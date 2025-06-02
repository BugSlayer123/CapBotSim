# frozen_string_literal: true

module Physics
  module Shape
    class Shape
      extend Forwardable
      attr_reader :x, :y, :mass
      attr_accessor :location, :rotation

      def_delegators :@location, :x, :y
      def initialize(location, mass)
        @location = location
        @mass = mass
        @rotation = 0
      end

      def change_location(vector)
        @location += vector
      end

      def center
        raise NotImplementedError, "#{self.class} must implement center method"
      end

      def width
        raise NotImplementedError, "#{self.class} must implement width method"
      end

      def height
        raise NotImplementedError, "#{self.class} must implement height method"
      end

      def overlap?(shape)
        raise NotImplementedError, "#{self.class} must implement overlaps_with method"
      end

      def corrected_overlap_locations(shape)
        raise NotImplementedError, "#{self.class} must implement corrected_overlap_locations method"
      end

      def intersection(shape)
        raise NotImplementedError, "#{self.class} must implement intersection method"
      end

      def create_ruby2d_shape
        raise NotImplementedError, "#{self.class} must implement create_ruby2d_shape method"
      end
    end
  end
end
