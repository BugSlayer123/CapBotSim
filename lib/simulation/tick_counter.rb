# frozen_string_literal: true

module Simulation
  class TickCounter
    include Singleton

    attr_accessor :tick

    def initialize
      @tick = 0
    end

    def self.tick
      instance.tick
    end

    def self.increment_tick
      instance.tick += 1
    end

    def self.reset
      instance.tick = 0
    end
  end
end
