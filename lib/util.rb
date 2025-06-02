# frozen_string_literal: true

module Util
  def deep_transform_keys(value, &block)
    case value
    when Hash
      value.transform_keys(&block).transform_values { |v| deep_transform_keys(v, &block) }
    when Array
      value.map { |v| deep_transform_keys(v, &block) }
    else
      value
    end
  end

  def distance_to(x, y)
    Math.sqrt(((x - self.x)**2) + ((y - self.y)**2))
  end

  def distance_between(point_a, point_b)
    Math.hypot(point_b[:x] - point_a[:x], point_b[:y] - point_a[:y])
  end

  def angle_to(x, y)
    Math.atan2(y - self.y, x - self.x)
  end
end
