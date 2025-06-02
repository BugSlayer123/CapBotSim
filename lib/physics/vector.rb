# frozen_string_literal: true

module Physics
  class Vector
    attr_accessor :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def *(other)
      apply_operation(other) { |a, b| a * b }
    end

    def /(other)
      apply_operation(other) { |a, b| a / b }
    end

    def +(other)
      apply_operation(other) { |a, b| a + b }
    end

    def -(other)
      apply_operation(other) { |a, b| a - b }
    end

    def -@
      Vector.new(-@x, -@y)
    end

    def [](index)
      case index
      when :x, 0 then x
      when :y, 1 then y
      else raise ArgumentError, "Invalid index #{index}"
      end
    end

    def rotation
      Math.atan2(@y, @x) * 180.0 / Math::PI % 360.0
    end

    def round(x)
      Physics::Vector.new(@x.round(x), @y.round(x))
    end

    def angle
      Math.atan2(@y, @x) % (Math::PI * 2)
    end

    def magnitude
      Math.hypot(@x, @y)
    end

    def normalized
      return 0 if magnitude.zero?

      self / magnitude
    end

    def same_direction?(other)
      normalized.dot(other.normalized) > 0.99
    end

    def distance(other: Physics::Vector.new(0, 0))
      Math.sqrt(((@x - other.x)**2) + ((@y - other.y)**2))
    end

    def dot(other)
      (x * other.x) + (y * other.y)
    end

    def dot_product(other)
      ((x * other.x) + (y * other.y)) / (magnitude + other.magnitude)
    end

    def rotate(radians)
      Vector.new((@x * Math.cos(radians)) - (@y * Math.sin(radians)), (@x * Math.sin(radians)) + (@y * Math.cos(radians)))
    end

    def rotate_cos_sin(cos, sin)
      Vector.new(
        (x * cos) - (y * sin),
        (x * sin) + (y * cos),
      )
    end

    def angle_to(other)
      Math.atan2(other.y - @y, other.x - @x)
    end

    def perpendicular
      Vector.new(-@y, @x)
    end

    def clamp(min, max)
      Vector.new(x.clamp(min, max), y.clamp(min, max))
    end

    def limited(max_magnitude)
      current_mag = magnitude
      if current_mag <= max_magnitude || current_mag.zero?
        dup
      else
        scale_factor = max_magnitude / current_mag
        Vector.new(@x * scale_factor, @y * scale_factor)
      end
    end

    def zero?
      @x.zero? && @y.zero?
    end

    def ==(other)
      @x == other.x && @y == other.y
    end

    def to_s
      "(#{@x}, #{@y})"
    end

    private

    def apply_operation(other, &block)
      if other.is_a?(Physics::Vector)
        Vector.new(block.call(@x, other.x), block.call(@y, other.y))
      else
        Vector.new(block.call(@x, other), block.call(@y, other))
      end
    end
  end

  Vector::ZERO = Vector.new(0, 0).freeze
end
