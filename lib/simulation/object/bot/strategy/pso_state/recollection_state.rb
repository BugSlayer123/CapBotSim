# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Strategy
        module PsoState
          class RecollectionState < BaseState
            def initialize(strategy, path, on_path_change, target = :end_nest, recollection_segment: nil)
              super(strategy, path, on_path_change)
              @target = target

              @path.on_path_change = method(:update_current)
              @path.navigate_to(@strategy.x, @strategy.y, target: @target, current_segment: recollection_segment)
              @no_interruption = !recollection_segment.nil?
              @obstacle_count = 0
              @pause = 0

              pp "Bot #{@bot.id} is in recollection state" if Constants::Simulation::DEBUG

              next_segment = @path.next
              next_segment = @path.last_segment if next_segment.nil?
              potential_fields(next_segment)
              run_pf
            end

            def tick(second_passed)
              return if @potential_fields.nil?

              if @potential_fields.reached_target?
                advance_waypoint
              else
                return unless second_passed

                @pause -= 1

                return if @pause.positive?

                run_pf
              end
            end

            def abort_bot_collision
              @strategy.collision_mapping.add_bot_collision(
                @strategy.x,
                @strategy.y,
                Constants::Strategy::Pso::Exploration::BOT_COLLISION_TIME_TO_LIVE,
              )
              @strategy.avoid_collision(rand(170..190))
              @pause = Constants::Strategy::Pso::Recollection::COLLISION_COOLDOWN
            end

            def abort_collision(other)
              @path.record_skipped_segment(x: @strategy.x, y: @strategy.y)

              case other
              when Obstacle::Station
                consider_state_transition
                return
              when Bot
                @strategy.collision_mapping.add_bot_collision(
                  @strategy.x,
                  @strategy.y,
                  Constants::Strategy::Pso::Exploration::BOT_COLLISION_TIME_TO_LIVE,
                )
                @pause = Constants::Strategy::Pso::Recollection::COLLISION_COOLDOWN
              else
                @obstacle_count += 1
                @strategy.collision_mapping.add_static_obstacle(@strategy.x, @strategy.y)

                p_go_back = Constants::Strategy::Pso::Recollection::RECOLLECTION_PROBABILITY
                if !@no_interruption && rand < p_go_back * Constants::Bot::ENERGY_FACTOR.call(@bot.energy)
                  @path.skip_failed
                  @strategy.recollect(@path, @on_path_change, other_nest, recollection_segment: @path.current_segment)
                  return
                end
                if @obstacle_count >= 3
                  @path.skip_failed
                  potential_fields(@path.current_segment)
                end
              end

              @strategy.avoid_collision(rand(170..190))
            end

            private

            def advance_waypoint
              if @path.segments.count <= 3
                @strategy.explore_target(@path, @on_path_change)
                return
              end
              @obstacle_count = 0
              max_skip = (Constants::Strategy::Pso::Recollection::MAX_SKIP_PERCENTAGE * @path.segments.count / 100).to_i.clamp(0, @path.segments.count - 2)
              skip_count = if @path.segments.count >= 5
                             rand < Constants::Strategy::Pso::Recollection::SKIP_PROBABILITY ? rand(1..max_skip + 1) : 0
                           else
                             0
                           end
              segment = @path.next(skip: skip_count) # TODO: smart skips (collisions and bot collisions)
              if segment.nil?
                @path.finish_navigation
                consider_state_transition
                return
              end

              potential_fields(segment)
            end

            def consider_state_transition
              on_path_change

              (best_path, on_path_change) = @strategy.best_path
              if best_path.found_target?
                @strategy.recollect(best_path, on_path_change, other_nest)
                return
              end

              p_go_back = Constants::Strategy::Pso::Recollection::RECOLLECTION_PROBABILITY
              p_exploration = Constants::Strategy::Pso::Recollection::EXPLORATION_PROBABILITY

              if @target == :end_nest
                if rand <= p_exploration / (1 + Constants::Bot::ENERGY_FACTOR.call(@bot.energy))
                  @strategy.explore_target(@strategy.paths[:current], @on_path_change)
                else
                  @strategy.recollect(@path, @on_path_change, :start_nest)
                end

              elsif rand <= p_go_back
                @strategy.recollect(@strategy.paths[:current], @on_path_change, :end_nest)
              else
                @strategy.explore_target(Path::Path.new(@strategy.collision_mapping, segments: [@path.segments.first]), @on_path_change)
              end
            end

            def potential_fields(segment)
              @potential_fields = PotentialFields.new(
                @strategy,
                @path,
                segment,
                Constants::Strategy::Pso::Recollection::ATTRACTIVE_FORCE_SCALE,
              )
            end

            def other_nest
              @target == :end_nest ? :start_nest : :end_nest
            end

            def run_pf
              new_force = @potential_fields.calculate_force
              return if new_force.nil?

              update_velocity(new_force)
              @path.record_skipped_segment(x: @strategy.x, y: @strategy.y)
            end
          end
        end
      end
    end
  end
end
