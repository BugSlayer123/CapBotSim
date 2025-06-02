# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Communication
        class CommunicationManager
          attr_reader :bot, :other_bot
          attr_accessor :current_communication, :collision_cooldowns

          def initialize(bot)
            @bot = bot
            @other_bot = nil

            @collision_cooldowns = {}
            @current_communication = nil
          end

          def active_communication?
            !@current_communication.nil?
          end

          def communicating_with?(other_bot)
            active_communication? &&
              @current_communication.involved_bots.include?(other_bot)
          end

          def initiate_communication_for_collision(other, accepts)
            return :wait if @bot.busy?
            return :abort if obstacle?(other)

            return handle_non_bot_collision(other) unless other.is_a?(Bot)

            return :wait if communicating_with?(other)

            can_start_communication?(other, accepts) ? start_communication(other) : :abort
          end

          def respond_to_request
            @bot.busy? ? :reject : :accept
          end

          def reset_communication
            @current_communication = nil
            @other_bot&.reset_communication
            @other_bot = nil
          end

          private

          def obstacle?(other_bot)
            other_bot.instance_of?(Obstacle::Obstacle)
          end

          def handle_non_bot_collision(other)
            current_time = CapBotSimulation.seconds_passed
            if @collision_cooldowns[other.id].nil? || @collision_cooldowns[other.id] + Constants::Bot::COLLISION_COOLDOWN < current_time
              @collision_cooldowns[other.id] = current_time
              :success
            else
              :wait
            end
          end

          def can_start_communication?(other_bot, accepts)
            return false if active_communication? || other_bot.active_communication?
            return false if @bot.busy? || other_bot.busy? || !accepts

            cooldown_end = @collision_cooldowns[other_bot.id]
            current_time = CapBotSimulation.seconds_passed

            !(cooldown_end && current_time < cooldown_end + Constants::Bot::COLLISION_COOLDOWN)
          end

          def start_communication(other_bot)
            current_time = CapBotSimulation.seconds_passed

            @collision_cooldowns[other_bot.id] = current_time
            other_bot.collision_cooldowns[@bot.id] = current_time

            communication = Communication.new(@bot, other_bot)
            establish_communication(communication, other_bot)
          end

          def establish_communication(communication, other_bot)
            @current_communication = communication
            @other_bot = other_bot
            other_bot.current_communication = communication

            success = communication.evaluate_communication(
              respond_to_request,
              other_bot.respond_to_request,
            )

            success ? :success : abort_communication
          end

          def abort_communication
            reset_communication
            :abort
          end
        end
      end
    end
  end
end
