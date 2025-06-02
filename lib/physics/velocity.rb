# frozen_string_literal: true

module Physics
  class Velocity < Vector
    def initialize(x = 0, y = 0, target_x = 0, target_y = 0)
      super(x, y)
      @target = Vector.new(target_x, target_y)
    end

    def target=(target)
      @target = target

      if magnitude == target.magnitude
        @x = target.x
        @y = target.y
        return
      end

      update
    end

    def update
      return self if at_target?

      delta_velocity = @target - self
      acceleration_step = delta_velocity.normalized * Constants::Bot::ACCELERATION

      new_velocity = self + acceleration_step

      if new_velocity.magnitude > Constants::Bot::MAX_SPEED
        normalized_velocity = new_velocity.normalized * Constants::Bot::MAX_SPEED
        @x = normalized_velocity.x
        @y = normalized_velocity.y
      else
        @x = new_velocity.x
        @y = new_velocity.y
      end

      self
    end

    def at_target?
      (self - @target).magnitude < 1e-6
    end
  end
end
