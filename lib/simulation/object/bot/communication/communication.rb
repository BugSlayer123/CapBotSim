# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Communication
        class Communication
          def initialize(bot1, bot2)
            @bot1 = bot1
            @bot2 = bot2
          end

          def involved_bots
            [@bot1, @bot2]
          end

          def evaluate_communication(response1, response2)
            response1 == :accept && response2 == :accept
          end
        end
      end
    end
  end
end
