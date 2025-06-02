# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Capabilities
        module Compass
          def rotation
            @bot.drain_energy(Constants::Capabilities::Compass::ENERGY_CONSUMPTION)
            @bot.shape.rotation
          end
        end
      end
    end
  end
end
