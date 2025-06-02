# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Tasks
        class TaskManager
          TASK_MAP = {
            Obstacle::Station => %i[charge data_station_transfer abort_collision],
            Obstacle::TargetStation => %i[charge data_station_transfer abort_collision],
            Bot => %i[trophallaxis data_transfer abort_bot_collision],
          }.freeze

          def initialize(bot)
            @bot = bot
            @tasks = []
          end

          def tick_tasks
            return if @tasks.empty?

            complete_current_task if @tasks.first.tick
          end

          def collision_task(collided_object)
            TASK_MAP.fetch(collided_object.class, []).each do |task_type|
              add_task(task_for(task_type, collided_object))
            end
            abort_task
          end

          def abort_task
            add_task(Tasks::AbortTask.new(@bot, 2))
          end

          private

          def task_for(type, target)
            case type
            when :charge then ChargeTask.new(@bot, target)
            when :data_transfer then DataTransferTask.new(@bot, target)
            when :data_station_transfer then DataStationTransferTask.new(@bot, target)
            when :trophallaxis then TrophallaxisTask.new(@bot, target)
            when :abort_collision then AbortCollisionTask.new(@bot, target)
            when :abort_bot_collision then AbortBotCollisionTask.new(@bot, target)
            else
              raise ArgumentError, "Unknown task type: #{type}"
            end
          end

          def add_task(task)
            @tasks << task
            start_next_task if @tasks.size == 1
          end

          def start_next_task(shift: false)
            @tasks.shift if shift
            @tasks.first&.start
          end

          def complete_current_task
            current_task = @tasks.first
            current_task.finish
            start_next_task(shift: true)
            @bot.reset_communication if @tasks.empty?
          end
        end
      end
    end
  end
end
