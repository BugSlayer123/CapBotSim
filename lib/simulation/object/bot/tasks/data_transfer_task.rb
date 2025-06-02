# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Tasks
        class DataTransferTask < CollisionTask
          def initialize(bot1, bot2)
            super(bot1, Constants::Bot::DATA_TRANSFER_DURATION, :data_transfer, bot2)
          end

          def collision_task
            @bot.add_data(@object.data)
          end
        end
      end
    end
  end
end
