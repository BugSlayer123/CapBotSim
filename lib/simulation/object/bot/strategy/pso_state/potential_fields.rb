# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Strategy
        module PsoState
          class PotentialFields
            def initialize(strategy, path, target, attractive_scale = 1)
              @strategy = strategy
              @path = path
              @target = Physics::Vector.new(target[:x], target[:y])
              @attractive_scale = attractive_scale
              @previous_force = nil
            end

            def calculate_force
              force = total_force
              should_adjust = should_adjust_direction?(force)

              return nil unless should_adjust

              calculate_direction(force)
            end

            def reached_target?
              @strategy.distance_to(@target.x, @target.y) < Constants::Strategy::Pso::WAYPOINT_THRESHOLD
            end

            private

            def calculate_direction(total)
              return nil if total.magnitude.zero?

              smoothed_force = if @previous_force
                                 (total * 0.7) + (@previous_force * 0.3)
                               else
                                 total
                               end

              angle_diff = if @previous_force
                             smoothed_force.angle_to(@previous_force).abs
                           else
                             Math::PI
                           end

              return nil unless angle_diff > (Constants::Strategy::Pso::PotentialFields::ADJUST_THRESHOLD / 180.0 * Math::PI)

              @previous_force = smoothed_force

              angle = smoothed_force.angle
              speed = calculate_adaptive_speed
              Physics::Vector.new(Math.cos(angle), Math.sin(angle)).normalized * speed
            end

            def calculate_adaptive_speed
              base_speed = Constants::Bot::MAX_SPEED
              distance = @strategy.distance_to(@target.x, @target.y)
              normalized_dist = [distance / Constants::Strategy::Pso::SLOW_DOWN_RANGE, 1.0].min
              slowdown_factor = (1.0 / Math.exp(1 - normalized_dist))**4 # TODO: better slowdown function

              (base_speed * slowdown_factor).clamp(Constants::Bot::MIN_SPEED, Constants::Bot::MAX_SPEED)
            end

            def should_adjust_direction?(force)
              base_prob = Constants::Strategy::Pso::PotentialFields::ADJUST_PROBABILITY
              force_mag = force.magnitude
              rand < base_prob * Math.tanh(force_mag / @strategy.force_normalization)
            end

            def total_force
              attractive = attractive_force
              repulsive = repulsive_force
              social = social_force

              begin
                total = (attractive * @strategy.attractive_weight) +
                        (repulsive * @strategy.repulsive_weight) +
                        (social * @strategy.social_weight)
              rescue TypeError
                pp "attractive: #{attractive}, repulsive: #{repulsive}, social: #{social}"
                pp "weights attractive: #{@strategy.attractive_weight}, repulsive: #{@strategy.repulsive_weight}, social: #{@strategy.social_weight}"
                raise 'Error in total force calculation'
              end
              total.limited(@strategy.max_force)
            end

            def attractive_force
              diff = @target - Physics::Vector.new(@strategy.x, @strategy.y)
              magnitude = diff.magnitude
              return Physics::Vector.new(0, 0) if magnitude <= 1e-3

              d = 1 + Math.log(magnitude)
              d_star = (1 + Math.log(Constants::Strategy::Pso::PotentialFields::D_STAR))
              e = @attractive_scale

              # Conisch veld: kwadratisch onder d_star, lineair daarboven
              mag = if d <= d_star
                      e * d
                    else
                      e * d_star
                    end

              diff.normalized * mag
            end

            def repulsive_force
              force = Physics::Vector.new(0, 0)
              bot_position = Physics::Vector.new(@strategy.x, @strategy.y)
              clustered_obstacles = cluster_collision_points(@path.obstacles).map { |o| Physics::Vector.new(o[:x], o[:y]) }

              clustered_obstacles.each do |obstacle_center|
                to_obstacle = bot_position - obstacle_center
                distance = to_obstacle.magnitude
                force_magnitude = 1
                next if distance.zero?

                unless distance < Constants::Strategy::Pso::PotentialFields::REPULSIVE_FORCE_RADIUS
                  next unless rand < 0.4

                  force_magnitude = 0.8
                end

                force_magnitude *= @strategy.repulsion_base / (distance**@strategy.repulsive_exp)

                force += to_obstacle.normalized * force_magnitude
                # term = ((1.0/Constants::Strategy::Pso::PotentialFields::REPULSIVE_FORCE_RADIUS) - (1.0/distance))
                #                 magnitude = term / (distance ** 2)
                #
                #                 force_direction = (bot_position - obstacle_center).normalized

                # force += force_direction * magnitude
              end

              force
            end

            def cluster_collision_points(collisions, radius: Constants::Strategy::Pso::PotentialFields::OBSTACLE_CLUSTER_RADIUS)
              return [] if collisions.empty?

              clusters = []
              collisions.each do |collision|
                pos = Physics::Vector.new(collision[:x], collision[:y])

                nearest = clusters.min_by { |c| (c - pos).magnitude }

                if nearest && (nearest - pos).magnitude < radius
                  clusters[clusters.index(nearest)] = (nearest + pos) / 2.0
                else
                  clusters << pos
                end
              end

              clusters
            end

            def social_force
              force = Physics::Vector.new(0, 0)
              # negative at first
              energy_factor = (Constants::Bot::ENERGY_FACTOR.call(@strategy.bot.energy) - 0.5) * Constants::Strategy::Pso::PotentialFields::SOCIAL_ENERGY_FACTOR
              cs = @path.bot_collisions(CapBotSimulation.seconds_passed)

              cs.each do |collision_raw|
                collision = Physics::Vector.new(collision_raw[:x], collision_raw[:y])
                diff = collision - Physics::Vector.new(@strategy.x, @strategy.y)
                distance = diff.magnitude
                next if distance.zero?

                next unless distance < Constants::Strategy::Pso::PotentialFields::SOCIAL_FORCE_RADIUS

                force_magnitude = @strategy.social_base /
                                  (distance**@strategy.social_exp) *
                                  energy_factor
                force += distance * force_magnitude
              end
              force
            end
          end
        end
      end
    end
  end
end
