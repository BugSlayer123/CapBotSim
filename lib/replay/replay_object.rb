# frozen_string_literal: true

module Replay
  class ReplayObject
    extend Forwardable
    attr_reader :id, :data, :color, :energy, :status

    def_delegators :@shape, :width, :height, :create_ruby2d_shape, :location, :rotation, :center

    def initialize(shape, *args)
      @shape = shape
      @id, @energy, @data, @vel_x, @vel_y, @status, @color, @type = args
    end

    def velocity
      Physics::Vector.new(@vel_x, @vel_y)
    end

    def x
      @shape.location.x
    end

    def y
      @shape.location.y
    end

    def bot?
      @type == :bot
    end
  end
end
