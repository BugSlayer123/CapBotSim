# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Tasks
        class ChargeTask < CollisionTask
          def initialize(bot, station)
            super(bot, Constants::Bot::CHARGE_DURATION, :trophallaxis, station)
          end

          def collision_task
            @bot.energy = Constants::Bot::MAX_ENERGY_LEVEL
          end
        end
      end
    end
  end
end
