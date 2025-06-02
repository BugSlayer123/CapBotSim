# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Strategy
        class BiasedStroll < BaseStrategy
          include Capabilities::Compass

          def initialize(bot, target, start)
            super

            @adjust_countdown = -1

            self.target = target
          end

          def target=(target)
            @target = target
            @target_rotation = target_rotation

            avoid_collision(@target_rotation + rand(-20..20) - rotation)
          end

          def tick(second_passed)
            return unless second_passed

            @bot.drain_energy(Constants::Capabilities::Compass::IDLE_POWER)

            adjust_course if @adjust_countdown.zero?
            return unless @adjust_countdown > -1

            @adjust_countdown -= 1
          end

          def abort_collision(_other)
            back_up = rand < 0.4

            if back_up
              avoid_collision(rand(150..210))
            else
              avoid_collision(rand(-120..-60))
            end

            @adjust_countdown = Constants::Strategy::BiasedStroll::ADJUST_COUNTDOWN
          end

          def abort_bot_collision
            avoid_collision(rand(90..270))

            @adjust_countdown = Constants::Strategy::BiasedStroll::ADJUST_COUNTDOWN
          end

          private

          def target_rotation
            start_vector = @bot.location.dup
            target_vector = Physics::Vector.new(@target[:x], @target[:y])
            direction = target_vector - start_vector
            rotation_degrees = direction.rotation

            normalize(rotation_degrees)
          end

          def escape_rotation(min_escape, max_escape)
            min_n = normalize(min_escape)
            max_n = normalize(max_escape)

            escape_rotation = if @target_rotation >= min_n && @target_rotation <= max_n
                                @target_rotation
                              elsif (@target_rotation - min_n).abs < (max_n - @target_rotation).abs
                                min_n
                              else
                                max_n
                              end

            escape_rotation % 360
          end

          def adjust_course
            delta_rotation = Constants::Strategy::BiasedStroll::ADJUST_DELTA_ROTATION
            adjusted_rotation = escape_rotation(rotation - delta_rotation, rotation + delta_rotation)
            @bot.turn_to(adjusted_rotation)
            @adjust_countdown = Constants::Strategy::BiasedStroll::ADJUST_COUNTDOWN
          end
        end
      end
    end
  end
end
