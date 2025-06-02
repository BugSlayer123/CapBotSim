# frozen_string_literal: true

module Replay
  class Replayer
    def initialize(configuration_path, bot_ids)
      @config = ReplayConfig.new(configuration_path, bot_ids: bot_ids)
      @graphics_manager = Graphics::GraphicsManager.new([], @config.method(:energy), @config.width, @config.height, method(:tick))

      @time_accumulated = 0
    end

    def start
      @graphics_manager.start
    end

    private

    def tick
      time_per_tick = 1.0 / Constants::Simulation::TICKS_PER_SECOND
      current_time = Time.now.to_f

      @last_tick_time ||= current_time
      delta_time = current_time - @last_tick_time
      @time_accumulated += delta_time

      while @time_accumulated >= time_per_tick
        tick_objects = @config.objects(Simulation::TickCounter.tick)
        @graphics_manager.display(objects: tick_objects, update_locations: true) if tick_objects

        @time_accumulated -= time_per_tick
        Simulation::TickCounter.increment_tick
      end

      @last_tick_time = current_time
    end
  end
end
