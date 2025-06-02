# frozen_string_literal: true

module Simulation
  class CapBotSimulation
    attr_accessor :width, :height

    def initialize(configuration_path, map_path, headless: false, width: nil, height: nil, no_log: false)
      config = SimulationConfig.new(configuration_path, map_path, width: width, height: height)

      @logger = Logger::Logger.new
      @csv_logger = Logger::CsvLogger.new("#{config.name}-#{Time.now.to_s.split('+').first.strip.tr(' ', '_')}.csv") unless no_log

      @object_manager = Simulation::Object::ObjectManager.new(
        config.bots,
        config.obstacles,
        config.station,
        config.target_station,
      )

      unless headless
        @graphics_manager = Graphics::GraphicsManager.new(
          @object_manager.objects,
          @object_manager.method(:energy),
          config.width,
          config.height,
          method(:tick),
          left_click_handler: method(:handle_left_click),
        )
      end
      @time_accumulated = 0

      @width = config.width || width
      @height = config.height || height
    end

    def self.seconds_passed
      TickCounter.tick
    end

    def start
      if @graphics_manager
        @graphics_manager.start
        return
      end

      time_per_tick = 1.0 / Constants::Simulation::TICKS_PER_SECOND

      loop do
        current_time = Time.now.to_f

        second_passed = (TickCounter.tick % 60).zero?
        log_interval_passed = (TickCounter.tick % Constants::Simulation::TICKS_PER_LOG).zero?

        @object_manager.tick(second_passed)

        @logger.show_logs if second_passed
        @csv_logger&.log(TickCounter.tick, @object_manager.bots, @object_manager.station, @object_manager.target_station) if log_interval_passed
        TickCounter.increment_tick

        elapsed_time = Time.now.to_f - current_time
        @max_tps = 1.0 / elapsed_time if elapsed_time.positive?

        sleep_time = time_per_tick - elapsed_time
        sleep(sleep_time) if sleep_time.positive?

        puts "Tick: #{TickCounter.tick}, minute:#{(TickCounter.tick.to_f / 3600).round(2)} | Max TPS: #{@max_tps.round(2)}" if (TickCounter.tick % 1000).zero?
      end
    end

    private

    def tick
      time_per_tick = 1.0 / Constants::Simulation::TICKS_PER_SECOND
      current_time = Time.now.to_f

      @last_tick_time ||= current_time
      delta_time = current_time - @last_tick_time
      @time_accumulated += delta_time

      while @time_accumulated >= time_per_tick
        second_passed = (TickCounter.tick % 60).zero?
        log_interval_passed = (TickCounter.tick % Constants::Simulation::TICKS_PER_LOG).zero?

        @object_manager.tick(second_passed)
        @graphics_manager.display

        @logger.show_logs if (TickCounter.tick % (60 * 5)).zero?
        @graphics_manager.show_paths if second_passed
        @csv_logger&.log(TickCounter.tick, @object_manager.bots, @object_manager.station, @object_manager.target_station) if log_interval_passed

        @time_accumulated -= time_per_tick
        TickCounter.increment_tick
      end

      @last_tick_time = current_time
    end

    def handle_left_click(position)
      bot = @object_manager.objects.nearby_nodes_at_position(position, 25).first
      @graphics_manager.clear_path

      unless bot
        @logger.disable_logs
        return
      end

      @logger.enable_logs(bot)
      @graphics_manager.enable_path(bot)
    end
  end
end
