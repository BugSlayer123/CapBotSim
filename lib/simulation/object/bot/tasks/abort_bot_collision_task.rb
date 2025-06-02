# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Tasks
        class AbortBotCollisionTask < CollisionTask
          def initialize(bot1, collided_object)
            super(bot1, 2, :abort, collided_object)
          end

          def collision_task
            @bot.abort_bot_collision
            @bot.status = :active_aborting
          end
        end
      end
    end
  end
end
