# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Strategy
        module PsoState
          class ExplorationState < BaseState
            def initialize(strategy, start_path, on_path_change, target)
              super(strategy, start_path, on_path_change)
              @potential_fields = PotentialFields.new(@strategy, @path, target)
              @avoiding = 0
              @rotate_count_down = 0

              new_force = @potential_fields.calculate_force
              update_velocity(new_force) if new_force

              pp "Bot #{@bot.id} is in exploration state" if Constants::Simulation::DEBUG
              @path.on_path_change = method(:update_current)

              record_current_position
            end

            def tick(second_passed)
              return unless second_passed

              if @rotate_count_down.positive?
                @rotate_count_down -= 1
                @strategy.avoid_collision(rand(-90..90)) if @rotate_count_down.zero?
              end

              if @avoiding.positive?
                @avoiding -= 1
                return
              end

              new_force = @potential_fields.calculate_force
              return unless new_force

              update_velocity(new_force)
              record_current_position
              consider_state_transition
            end

            def abort_collision(other)
              case other
              when Obstacle::TargetStation
                @path.add_found_station(other)

                on_path_change
                @strategy.recollect(@path, @on_path_change, :start_nest)
                return
              when Obstacle::Station
                (best_path, on_path_change) = @strategy.best_path
                @strategy.recollect(best_path, on_path_change, :end_nest)
                return
              when Bot
                @path.add_segment(x: @strategy.x, y: @strategy.y, bot_collision: true, seconds: Constants::Strategy::Pso::Exploration::BOT_COLLISION_TIME_TO_LIVE)
                return if @avoiding.positive?

                @avoiding = 5

                @strategy.avoid_collision(rand(90..270))
                return
              else
                @avoiding = 5
              end

              @strategy.avoid_collision(180)
              @rotate_count_down = 2
              @path.add_segment(x: @strategy.x, y: @strategy.y, collision: true)
            end

            def abort_bot_collision
              @strategy.avoid_collision(rand(90..270))
              @path.add_segment(x: @strategy.x, y: @strategy.y, bot_collision: true, seconds: Constants::Strategy::Pso::Exploration::BOT_COLLISION_TIME_TO_LIVE)

              (best_path, on_path_change) = @strategy.best_path
              return unless best_path.found_target?

              @strategy.recollect(best_path, on_path_change, :end_nest)
            end

            private

            def record_current_position
              @path.add_segment(x: @strategy.x, y: @strategy.y)
            end

            def consider_state_transition
              recollection = Constants::Strategy::Pso::Exploration::RECOLLECTION_PROBABILITY * Constants::Bot::ENERGY_FACTOR.call(@bot.energy)

              return if rand > recollection

              record_current_position
              (best_path, on_path_change) = @strategy.best_path
              @strategy.recollect(best_path, on_path_change, :start_nest)
            end
          end
        end
      end
    end
  end
end
