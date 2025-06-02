# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Tasks
        class TrophallaxisTask < CollisionTask
          def initialize(bot1, bot2)
            super(bot1, Constants::Bot::TROPHALLAXIS_DURATION, :trophallaxis, bot2)
            @average_energy = (bot1.energy + bot2.energy) / 2
          end

          def collision_task
            @bot.energy = @average_energy
          end
        end
      end
    end
  end
end
