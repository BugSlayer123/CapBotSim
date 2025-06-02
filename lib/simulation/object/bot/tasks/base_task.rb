# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Tasks
        class BaseTask
          attr_reader :seconds_left, :start_time
          attr_accessor :end_time

          def initialize(duration)
            @seconds_left = duration
            @start_time = Time.now
            @end_time = nil
          end

          def start
            on_start
          end

          def finish
            @end_time = Time.now
            on_finish
          end

          def tick
            @seconds_left -= 1

            return unless @seconds_left <= 0

            true
          end

          def involved_bots
            raise NotImplementedError, "#{self.class} must implement involved_bots method"
          end

          def on_start
            raise NotImplementedError, "#{self.class} must implement on_start method"
          end

          def on_finish
            raise NotImplementedError, "#{self.class} must implement on_finish method"
          end
        end
      end
    end
  end
end
