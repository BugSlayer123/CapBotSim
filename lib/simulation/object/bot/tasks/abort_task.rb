# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Tasks
        class AbortTask < BaseTask
          def initialize(bot, seconds)
            @bot = bot

            super(seconds)
          end

          def on_start
            @bot.status = :active_aborting
          end

          def on_finish
            @bot.status = :active
          end
        end
      end
    end
  end
end
