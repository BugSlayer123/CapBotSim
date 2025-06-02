# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Strategy
        class RandomStroll < BaseStrategy
          def initialize(bot, target, start)
            super
            avoid_collision(rand(-90..90))
          end

          def tick(_second_passed)
            nil
          end

          def abort_collision(_other)
            back_up = rand < 0.4

            if back_up
              avoid_collision(rand(150..210))
            else
              avoid_collision(rand(-120..-60))
            end
          end

          def abort_bot_collision
            avoid_collision(rand(90..270))
          end
        end
      end
    end
  end
end
