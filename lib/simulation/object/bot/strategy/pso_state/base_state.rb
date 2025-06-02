# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Strategy
        module PsoState
          class BaseState
            def initialize(strategy, path, on_path_change)
              @strategy = strategy
              @bot = strategy.bot
              initialize_state

              @on_path_change = on_path_change
              @path = path.clone
            end

            def abort_collision(other)
              if other.is_a?(Obstacle::TargetStation)
                @path.add_found_station(other)

                @strategy.state = RecollectionState.new(@strategy, @path, :start_nest)
                return
              elsif other.is_a?(Obstacle::Station)
                @path.add_found_station(other)

                @strategy.state = RecollectionState.new(@strategy, @path, :end_nest)
                return
              end

              @strategy.avoid_collision(rand(170..190))
              @path.add_segment(x: @strategy.x, y: @strategy.y, collision: true)
            end

            protected

            def update_velocity(vector)
              @bot.update_velocity(vector)
            end

            def update_current
              @strategy.paths[:current] = @path
            end

            def on_path_change
              @strategy.paths[:current] = @path
              @on_path_change.call
            end

            def initialize_state
              @strategy.set_velocity(rand(0..360) * Math::PI / 180)
            end

            def record_current_position(metadata = {})
              @path.add_segment(x: @strategy.x, y: @strategy.y, **metadata)
            end
          end
        end
      end
    end
  end
end
