# frozen_string_literal: true

module Physics
  module Shape
    class BoundingBox
      attr_reader :min, :max

      def initialize(min_point, max_point)
        @min = min_point
        @max = max_point
      end

      def intersects?(other)
        # Check for separating axis
        @min.x <= other.max.x &&
          @max.x >= other.min.x &&
          @min.y <= other.max.y &&
          @max.y >= other.min.y
      end

      def contains?(object)
        case object
        when BoundingBox
          object.corners.any? { |c| contains?(c) }
        when Physics::Vector
          object.x >= @min.x && object.x <= @max.x &&
            object.y >= @min.y && object.y <= @max.y
        end
      end

      def center
        Vector.new((@min.x + @max.x) / 2.0, (@min.y + @max.y) / 2.0)
      end

      def area
        width * height
      end

      def fatten!(fat_factor)
        padding_x = width * fat_factor / 2.0
        padding_y = height * fat_factor / 2.0
        @min -= Vector.new(padding_x, padding_y)
        @max += Vector.new(padding_x, padding_y)
        self
      end

      def fattened(fat_factor)
        padding_x = width * fat_factor / 2.0
        padding_y = height * fat_factor / 2.0
        BoundingBox.new(
          @min - Vector.new(padding_x, padding_y),
          @max + Vector.new(padding_x, padding_y),
        )
      end

      def width
        @max.x - @min.x
      end

      def height
        @max.y - @min.y
      end

      def expand!(padding)
        @min -= Vector.new(padding, padding)
        @max += Vector.new(padding, padding)
        self
      end

      def expanded(padding)
        BoundingBox.new(
          @min - Vector.new(padding, padding),
          @max + Vector.new(padding, padding),
        )
      end

      def merge(other)
        BoundingBox.new(
          Vector.new([@min.x, other.min.x].min, [@min.y, other.min.y].min),
          Vector.new([@max.x, other.max.x].max, [@max.y, other.max.y].max),
        )
      end

      def to_rect
        [@min.x, @min.y, width, height]
      end

      def corners
        [
          @min,
          Vector.new(@max.x, @min.y),
          @max,
          Vector.new(@min.x, @max.y),
        ]
      end

      def ==(other)
        @min == other.min && @max == other.max
      end

      def to_s
        "BoundingBox(#{@min} -> #{@max})"
      end
    end
  end
end
