# frozen_string_literal: true

module Experiment
  class Experimenter
    VALID_STOP_CONDITIONS = %i[reach_target reach_start ticks minutes depleted_bots].freeze

    def initialize(
      configuration_path,
      map_path,
      iterations:,
      stop_conditions: {},
      tweak_constants: {},
      log: false,
      kill_chance: 0,
      tps: nil
    )
      raise ArgumentError, 'At least one stop condition must be provided' if stop_conditions.empty?

      stop_conditions.each_key do |condition|
        raise ArgumentError, "Invalid stop condition: #{condition}" unless VALID_STOP_CONDITIONS.include?(condition)
      end
      stop_conditions[:ticks] = stop_conditions.delete(:minutes) * 3600 if stop_conditions[:minutes]

      @config = Simulation::SimulationConfig.new(configuration_path, map_path)
      @log = log
      @experiment_logger = Logger::ExperimentLogger.new("#{@config.name}-#{Time.now.to_s.split('+').first.strip.tr(' ', '_')}")
      @stop_conditions = stop_conditions
      @tweak_constants = tweak_constants
      @iterations = iterations
      @current_iteration = 0
      @kill_chance = kill_chance
      @biased = configuration_path.include?('biased')
      @time_per_tick = tps ? 1.0 / tps : nil

      init_iteration
    end

    def start
      start_time = Time.now

      loop do
        if stop_condition_reached?
          @experiment_logger.log_data(@current_iteration, Simulation::TickCounter.tick, @object_manager.station, :station)
          @experiment_logger.log_data(@current_iteration, Simulation::TickCounter.tick, @object_manager.target_station, :target_station)
          @experiment_logger.log_message(
            {
              message: 'stop_condition_reached',
              iteration: @current_iteration,
              tick: Simulation::TickCounter.tick,
              bots: @object_manager.bots.map { |bot| { id: bot.id, data: bot.data.filter(&:generic?).map(&:to_hash), energy: bot.energy } },
              station: @object_manager.station.data.filter(&:generic?).map(&:content).uniq.join(', '),
              target_station: @object_manager.target_station.data.filter(&:generic?).map(&:content).uniq.join(', '),
            },
          )

          @current_iteration += 1

          if @current_iteration >= @iterations
            duration = Time.now - start_time
            puts "Experiment finished in #{duration} seconds."
            @experiment_logger.log_message({ message: 'experiment_finished', duration: duration }, last: true)
            @experiment_logger.close
            break
          end

          init_iteration
        elsif @biased && (target_data = @stop_conditions[:reach_target]) && (start_data = @stop_conditions[:reach_start])
          target_contents = @object_manager.target_station.data.filter(&:generic?).map(&:content)
          target_found = target_contents.include?(target_data)
          if target_found
            @object_manager.bots.each do |bot|
              next if bot.depleted? || bot.data.filter(&:generic?).none? { |data| data.content == start_data } || @biased_target_updated.include?(bot.id)

              bot.strategy.target = { x: @object_manager.station.location.x, y: @object_manager.station.location.y }
              @biased_target_updated << bot.id
            end
          end
        end

        @experiment_logger.log_message({ message: 'all_depleted' }) if @object_manager.bots.all?(&:depleted?)

        if @csv_logger
          log_interval_passed = (Simulation::TickCounter.tick % Constants::Simulation::TICKS_PER_LOG).zero?
          @csv_logger.log(Simulation::TickCounter.tick, @object_manager.bots, @object_manager.station, @object_manager.target_station) if log_interval_passed
        end

        tick
      end
    end

    private

    def init_iteration
      Simulation::TickCounter.reset
      @biased_target_updated = []

      tweaks = {}
      @tweak_constants.each do |key, value|
        new_value = if value[:distribution]
                      original_min = value[:min]
                      original_max = value[:max]

                      shrink_factor = rand(0.0..0.9)

                      range_size = original_max - original_min
                      shrink_amount = range_size * shrink_factor

                      new_min = original_min + rand(0..shrink_amount)
                      new_max = original_max - rand(0..shrink_amount)

                      [new_min, new_max].sort
                    else
                      rand(value[:min]..value[:max])
                    end

        namespaces = key.split('::')
        constant_name = namespaces.pop
        current_module = Constants

        namespaces.each do |namespace|
          current_module = current_module.const_get(namespace)
        end
        current_module.const_set(constant_name, new_value)
        tweaks[key] = new_value
      end
      @experiment_logger.log_message({ message: 'tweaked_constants', tweaks: tweaks }) if tweaks.any?

      @object_manager = Simulation::Object::ObjectManager.new(
        @config.bots,
        @config.obstacles,
        @config.station,
        @config.target_station,
      )
      @csv_logger = Logger::CsvLogger.new("#{@config.name}-#{Time.now.to_s.split('+').first.strip.tr(' ', '_')}.csv") if @log
    end

    def tick
      tick_start = Time.now
      second_passed = (Simulation::TickCounter.tick % 60).zero?

      @object_manager.tick(second_passed)

      if second_passed && rand < @kill_chance
        @object_manager.bots.each do |bot|
          next if bot.depleted?

          bot.kill
          @experiment_logger.log_message({ message: 'bot_killed', id: bot.id, iteration: @current_iteration, tick: Simulation::TickCounter.tick })
          break
        end
      end

      Simulation::TickCounter.increment_tick
      puts "(Iteration #{@current_iteration}) Tick: #{Simulation::TickCounter.tick}" if (Simulation::TickCounter.tick % 1000).zero?

      return unless @time_per_tick

      elapsed = Time.now - tick_start
      sleep_time = @time_per_tick - elapsed
      sleep(sleep_time) if sleep_time.positive?
    end

    def stop_condition_reached?
      if @object_manager.bots.all?(&:depleted?)
        @experiment_logger.log_message({ message: 'all_depleted' })
        return true
      end

      if (ticks = @stop_conditions[:ticks]) && Simulation::TickCounter.tick >= ticks
        return true
      end

      if (target = @stop_conditions[:reach_target])
        target_contents = @object_manager.target_station.data.filter(&:generic?).map(&:content)
        target_found = target_contents.include?(target)

        if (start = @stop_conditions[:reach_start])
          start_contents = @object_manager.station.data.filter(&:generic?).map(&:content)
          return true if start_contents.include?(start) && target_found
        elsif target_found
          return true
        end
      end

      if (depleted = @stop_conditions[:depleted_bots])
        depleted_count = @object_manager.bots.count(&:depleted?)
        return true if depleted_count >= depleted
      end

      false
    end
  end
end
