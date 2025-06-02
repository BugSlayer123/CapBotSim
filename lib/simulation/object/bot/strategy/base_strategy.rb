# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Strategy
        class BaseStrategy
          def initialize(bot, _target, _start)
            @bot = bot
          end

          def tick(second_passed)
            raise NotImplementedError, "#{self.class} must implement update method"
          end

          def abort_collision(other)
            intersection = @bot.intersection(other.shape)
            separation_vector = intersection.nil? ? @bot.center - other.location : @bot.center - intersection
            @bot.change_location(separation_vector.normalized * Constants::Bot::PUSH_BACK)
            separation_vector.rotation
          end

          def avoid_collision(avoidance_rotation)
            escape_rot = normalize(@bot.rotation + avoidance_rotation)
            set_velocity(escape_rot * Math::PI / 180)
          end

          def set_velocity(angle, speed = Constants::Bot::MAX_SPEED)
            @bot.update_velocity(
              Physics::Vector.new(
                Math.cos(angle),
                Math.sin(angle),
              ).normalized * speed,
            )
          end

          def wants_trophallaxis?(_o)
            true
          end

          protected

          def normalize(rot)
            ((rot + 180) % 360) - 180
          end

          def generate_random_velocity(angle)
            speed = (0.5 + rand(0.5)) * Constants::Bot::MAX_SPEED

            x = Math.cos(angle)
            y = Math.sin(angle)

            Physics::Vector.new(x, y).normalized * speed
          end
        end
      end
    end
  end
end
