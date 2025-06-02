# frozen_string_literal: true

module Physics
  module Shape
    class Image < Rectangle
      attr_reader :sprite_path
      attr_accessor :rotation

      def initialize(location, mass, width, height, rotation, sprite_path)
        super(location, mass, width, height)
        @rotation = rotation % 360
        @sprite_path = sprite_path
        @last_position = location.dup
        @last_rotation = @rotation
      end

      def overlap?(other)
        case other
        when Physics::Vector
          closest_point = closest_point_on_rectangle(other)
          (closest_point - other).magnitude < 1
        when Image
          rectangles_overlap?(other)
        else
          raise NotImplementedError, "Cannot check overlap between #{self.class} and #{other.class}"
        end
      end

      def create_ruby2d_shape
        Ruby2D::Image.new(@sprite_path, x: x, y: y, width: @width, height: @height, rotate: @rotation)
      end

      def rotated?
        @rotation != 0
      end

      def intersection(other)
        rectangle_intersection(other)
      end

      def contains?(point)
        overlap?(point)
      end

      def rotate(rotation)
        @rotation = rotation % 360
      end

      def bounding_box
        return @aabb unless dirty?

        rad = @rotation * Math::PI / 180.0

        cos = Math.cos(rad).abs
        sin = Math.sin(rad).abs

        w = (@width * cos) + (@height * sin)
        h = (@width * sin) + (@height * cos)

        @aabb = BoundingBox.new(
          Physics::Vector.new(center.x - (w / 2), center.y - (h / 2)),
          Physics::Vector.new(center.x + (w / 2), center.y + (h / 2)),
        )
        @last_position = center.dup
        @last_rotation = @rotation
        @aabb
      end

      def project(axis)
        dots = corners.map { |c| c.dot(axis) }
        dots.minmax
      end

      def axes
        return @cached_axes if !dirty? && @cached_axes

        @cached_axes = edges.map do |p1, p2|
          edge = p2 - p1
          edge.perpendicular.normalized
        end.uniq
      end

      def move_by(vector)
        @location += vector
        @last_pos = center.dup
      end

      def corners
        # return @cached_corners if !dirty? && @cached_corners

        half_w = @width / 2.0
        half_h = @height / 2.0
        rad = @rotation * Math::PI / 180.0

        cos = Math.cos(rad)
        sin = Math.sin(rad)

        [
          Physics::Vector.new(-half_w, -half_h).rotate_cos_sin(cos, sin) + center,
          Physics::Vector.new(half_w, -half_h).rotate_cos_sin(cos, sin) + center,
          Physics::Vector.new(half_w, half_h).rotate_cos_sin(cos, sin) + center,
          Physics::Vector.new(-half_w, half_h).rotate_cos_sin(cos, sin) + center,
        ]
      end

      def edges
        corners.each_cons(2).to_a.tap { |e| e << [corners.last, corners.first] }
      end

      private

      def dirty?
        @last_position != center || @last_rotation != @rotation
      end

      def closest_point_on_rectangle(point)
        half_width = @width / 2.0
        half_height = @height / 2.0
        angle = @rotation * Math::PI / 180.0

        relative_x = point.x - center.x
        relative_y = point.y - center.y

        rotated_x = (Math.cos(-angle) * relative_x) - (Math.sin(-angle) * relative_y)
        rotated_y = (Math.sin(-angle) * relative_x) + (Math.cos(-angle) * relative_y)

        clamped_x = rotated_x.clamp(-half_width, half_width)
        clamped_y = rotated_y.clamp(-half_height, half_height)

        world_x = (Math.cos(angle) * clamped_x) - (Math.sin(angle) * clamped_y) + center.x
        world_y = (Math.sin(angle) * clamped_x) + (Math.cos(angle) * clamped_y) + center.y

        Vector.new(world_x, world_y)
      end
    end
  end
end
