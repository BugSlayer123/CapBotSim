# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Tasks
        class CollisionTask < BaseTask
          def initialize(bot, seconds, status, object)
            @bot = bot
            @object = object
            @status = status

            super(seconds)
          end

          # Current implementation
          # - every collision task happens after each other, followed with an abort collision to move them away
          def on_start
            @bot.status = @status
            @bot.rotate((@object.location - @bot.location).rotation)
          end

          def collision_task
            raise NotImplementedError, "#{self.class} must implement collision_task method"
          end

          def on_finish
            collision_task
          end
        end
      end
    end
  end
end
