# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      class Bot < Object
        extend Forwardable

        attr_reader :id, :strategy, :velocity
        attr_accessor :energy

        def_delegators :@communication_manager, :active_communication?, :respond_to_request, :reset_communication,
                       :current_communication=, :collision_cooldowns, :collision_cooldowns=, :initiate_communication_for_collision
        def_delegators :@task_manager, :busy?, :init_tasks, :collision_task, :tick_tasks, :abort_task
        def_delegators :@strategy, :abort_collision, :abort_bot_collision, :best_path, :current_path,
                       :personal_best_path, :global_best_path, :paths, :wants_trophallaxis?

        def initialize(id, location, mass, width, height, rotation, strategy_clazz, data, target, start)
          super(id, data)

          @velocity = Physics::Velocity.new
          @shape = Physics::Shape::Image.new(location, mass, width, height, rotation, 'sprites/bot.png')

          @energy = Constants::Bot::MAX_ENERGY_LEVEL
          @strategy = strategy_clazz.new(self, target, start)

          @task_manager = Tasks::TaskManager.new(self)
          @communication_manager = Communication::CommunicationManager.new(self)
        end

        def tick(second_passed, collided_objects)
          update_per_tick
          update_per_second if second_passed
          strategy.tick(second_passed) unless busy?
          return if collided_objects.empty?

          handle_collision(collided_objects)
        end

        def halt
          @velocity = Physics::Velocity.new
        end

        def kill
          @status = :depleted
          @task_manager.abort_task
          @communication_manager.reset_communication
          @strategy.abort_bot_collision
          @energy = 0
        end

        def update_velocity(new_velocity_target)
          @velocity.target = if new_velocity_target.magnitude > Constants::Bot::MAX_SPEED
                               new_velocity_target.normalized * Constants::Bot::MAX_SPEED
                             else
                               new_velocity_target
                             end
          self.rotation = @velocity.rotation % 360
        end

        def turn_to(rotation)
          angle = rotation * Math::PI / 180.0
          speed = @velocity.magnitude
          x = Math.cos(angle)
          y = Math.sin(angle)

          update_velocity(Physics::Vector.new(x, y).normalized * speed)
        end

        def color
          return [0.067, 0.067, 0.067, 1] if @status == :depleted
          return [0.94, 0.071, 0.75, 1] if @status == :trophallaxis
          return [0.69, 0.051, 0.79, 1] if @status == :data_transfer

          energy_ratio = (@energy - Constants::Bot::MIN_ENERGY_LEVEL).to_f /
                         (Constants::Bot::MAX_ENERGY_LEVEL - Constants::Bot::MIN_ENERGY_LEVEL)
          energy_ratio = energy_ratio.clamp(0, 1)

          [1 - energy_ratio, energy_ratio, 0, 1]
        end

        def handles_collisions?
          true
        end

        def busy?
          !(@status == :active || @status == :active_aborting)
        end

        def depleted?
          @status == :depleted
        end

        def drain_energy(amount)
          @energy -= amount
          @energy = [@energy, 0].max

          update_status
        end

        private

        def update_status
          @status = :depleted if @energy <= Constants::Bot::MIN_ENERGY_LEVEL
        end

        def handle_collision(collided_objects)
          return if busy?

          collided_objects.each do |collided_object|
            case initiate_communication_for_collision(collided_object, wants_trophallaxis?(collided_object))
            when :success
              halt
              collision_task(collided_object)
              if collided_object.handles_collisions?
                collided_object.collision_task(self)
                collided_object.halt
              end
            when :abort
              break if @status == :active_aborting

              halt
              abort_collision(collided_object)
              abort_task
            when :wait
              next
            end
          end
        end

        def move
          return if busy?

          change_location(@velocity.update)
          self.rotation = @velocity.rotation % 360
        end

        def update_per_tick
          move
        end

        def update_per_second
          drain_energy(Constants::Bot::CURRENT_POWER_USAGE.call(@velocity, !@velocity.at_target?))

          tasks_done = tick_tasks
          reset_communication if tasks_done
        end
      end
    end
  end
end
