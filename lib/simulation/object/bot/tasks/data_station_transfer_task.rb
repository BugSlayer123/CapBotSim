# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Tasks
        class DataStationTransferTask < CollisionTask
          def initialize(bot1, station)
            super(bot1, Constants::Bot::DATA_TRANSFER_DURATION, :data_transfer, station)
          end

          def collision_task
            @bot.add_data(@object.data)
            @object.add_data(@bot.data)
          end
        end
      end
    end
  end
end
