# frozen_string_literal: true

module Physics
  module Shape
    class Rectangle < Shape
      attr_reader :width, :height

      def initialize(location, mass, width, height)
        super(location, mass) # location is top left corner

        @width = width
        @height = height
      end

      def overlap?(shape)
        case shape
        when Circle
          shape.overlap?(self)
        when Rectangle
          rectangles_overlap?(shape)
        else
          raise NotImplementedError, "#{self.class} cannot check overlap with #{shape}"
        end
      end

      def rectangle_intersection(other)
        corners.each do |corner|
          return corner if other.contains?(corner)
        end

        other.corners.each do |corner|
          return corner if contains?(corner)
        end

        nil
      end

      def corrected_overlap_locations(shape)
        case shape
        when Circle
          shape.corrected_overlap_locations(self).reverse
        when Image
          correct_overlap_with_image(shape)
        when Rectangle
          correct_overlap_with_rectangle(shape)
        else
          raise NotImplementedError, "#{self.class} cannot check overlap with #{shape}"
        end
      end

      def intersection(shape)
        case shape
        when Circle
          shape.intersection(self)
        when Image, Rectangle
          rectangle_intersection(shape)
        else
          raise NotImplementedError, "Unsupported shape: #{shape.class}"
        end
      end

      def center
        @location + Physics::Vector.new(@width / 2, @height / 2)
      end

      def create_ruby2d_shape
        Ruby2D::Rectangle.new(x: x, y: y, width: @width, height: @height)
      end

      private

      def rectangles_overlap?(rectangle)
        return false if x + @width <= rectangle.x ||
                        rectangle.x + rectangle.width <= x ||
                        y + @height <= rectangle.y ||
                        rectangle.y + rectangle.height <= y

        true
      end

      def correct_overlap_with_rectangle(other_rectangle)
        half_width_a = @width / 2.0
        half_height_a = @height / 2.0
        half_width_b = other_rectangle.width / 2.0
        half_height_b = other_rectangle.height / 2.0

        center_a = Vector.new(@location.x + half_width_a, @location.y + half_height_a)
        center_b = Vector.new(other_rectangle.location.x + half_width_b, other_rectangle.location.y + half_height_b)

        delta = center_b - center_a

        overlap_x = (half_width_a + half_width_b) - delta.x.abs
        overlap_y = (half_height_a + half_height_b) - delta.y.abs

        return [Vector.new(0, 0), Vector.new(0, 0)] if overlap_x <= 0 || overlap_y <= 0

        separation_vector = if overlap_x < overlap_y
                              Vector.new(delta.x.negative? ? -overlap_x : overlap_x, 0)
                            else
                              Vector.new(0, delta.y.negative? ? -overlap_y : overlap_y)
                            end

        total_mass = @mass + other_rectangle.mass
        my_displacement = separation_vector * (other_rectangle.mass / total_mass)
        other_displacement = separation_vector * (@mass / total_mass)

        [-my_displacement, other_displacement]
      end

      def correct_overlap_with_image(image)
        # Use SAT to find collision normal between two rotated rectangles
        axes = self.axes + image.axes
        min_overlap = Float::INFINITY
        collision_axis = nil

        axes.each do |axis|
          a_min, a_max = project(axis)
          b_min, b_max = image.project(axis)

          overlap = [a_max, b_max].min - [a_min, b_min].max
          next if overlap <= 0 # No overlap on this axis

          if overlap < min_overlap
            min_overlap = overlap
            collision_axis = axis
          end
        end

        if collision_axis
          # Determine direction based on centers' positions
          direction_to_other = image.center - center
          collision_axis = -collision_axis if direction_to_other.dot(collision_axis).negative?

          # Calculate displacement based on mass ratio
          total_mass = @mass + image.mass
          my_ratio = image.mass / total_mass
          other_ratio = @mass / total_mass

          [
            collision_axis * min_overlap * my_ratio,
            -collision_axis * min_overlap * other_ratio,
          ]
        else
          # Fallback for edge cases (use vector between centers)
          fallback_vector = (center - image.center).normalized
          [
            fallback_vector * Constants::Bot::PUSH_BACK,
            -fallback_vector * Constants::Bot::PUSH_BACK,
          ]
        end
      end
    end
  end
end
