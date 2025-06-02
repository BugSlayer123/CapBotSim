# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Path
        class CollisionMapping
          def initialize
            @static_obstacles = Set.new
            @bot_collisions = []
          end

          def add_static_obstacle(x, y)
            @static_obstacles.add([x, y].freeze)
          end

          def add_bot_collision(x, y, ttl)
            @bot_collisions << { x: x, y: y, expires_at: CapBotSimulation.seconds_passed + ttl }
            purge_expired_bot_collisions(CapBotSimulation.seconds_passed)
          end

          def static_obstacles
            @static_obstacles.to_a.map { |coords| { x: coords[0], y: coords[1] } }
          end

          def bot_collisions(current_time)
            purge_expired_bot_collisions(current_time)
            @bot_collisions.dup
          end

          private

          def purge_expired_bot_collisions(current_time)
            @bot_collisions.reject! { |entry| entry[:expires_at] <= current_time }
          end
        end
      end
    end
  end
end
