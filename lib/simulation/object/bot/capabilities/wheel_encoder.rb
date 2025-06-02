# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Capabilities
        module WheelEncoder
          def x
            @bot.location.x
          end

          def y
            @bot.location.y
          end
        end
      end
    end
  end
end
