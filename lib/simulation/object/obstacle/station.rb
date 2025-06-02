# frozen_string_literal: true

module Simulation
  module Object
    module Obstacle
      class Station < Object
        def initialize(id, location, mass, width, height, rotation, data = [])
          super(id, data)
          @shape = Physics::Shape::Image.new(location, mass, width, height, rotation, 'sprites/white_rect.png')
        end

        def color
          [0, 0.45, 0.85, 1]
        end
      end
    end
  end
end
