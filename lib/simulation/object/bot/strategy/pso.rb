# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Strategy
        class Pso < BaseStrategy
          extend Forwardable
          include Capabilities::WheelEncoder
          include Util

          attr_reader :bot, :seconds, :attr_weight
          attr_accessor :collision_mapping, :paths

          def_delegators :@state, :abort_collision
          def_delegators :@pf_weights, :selfishness, :attractive_weight, :repulsive_weight, :repulsive_exp, :social_weight, :social_exp,
                         :max_attractive, :max_repulsive, :max_social, :max_force, :force_normalization, :repulsion_base, :social_base

          def initialize(bot, target, start)
            super
            @pf_weights = PsoState::PfWeights.new(@bot.id)
            @collision_mapping = Path::CollisionMapping.new
            @start_nest = Physics::Vector.new(start[:x], start[:y])
            @target_nest = Physics::Vector.new(target[:x], target[:y])
            @paths = {
              current: Path::Path.new(@collision_mapping),
              p_best: Path::Path.new(@collision_mapping),
              g_best: Path::Path.new(@collision_mapping),
            }
            @paths[:p_best].on_path_change = method(:store_path_data)

            start_path = @paths[:current]
            start_path.add_segment(x: @start_nest.x, y: @start_nest.y)
            start_path.add_segment(x: x, y: y)
            explore_target(start_path, method(:update_personal_best))
          end

          def tick(second_passed)
            @state.tick(second_passed)

            return if !second_passed || !(CapBotSimulation.seconds_passed % Constants::Strategy::Pso::REFRESH_RATE).zero?

            @bot.drain_energy(
              Constants::Capabilities::Compass::IDLE_POWER + Constants::Capabilities::WheelEncoder::POWER,
            )
          end

          def best_path
            p_best = @paths[:p_best]
            g_best = @paths[:g_best]

            return [@paths[:current], method(:update_personal_best)] if p_best.empty? && g_best.empty?
            return [p_best, method(:update_personal_best)] if !p_best.empty? && g_best.empty?
            return [g_best, method(:update_global_best)] if p_best.empty? && !g_best.empty?

            p_best.compare(g_best, @target_nest, selfishness).negative? ? [p_best, method(:update_personal_best)] : [g_best, method(:update_global_best)]
          end

          def abort_bot_collision
            update_global_best
            @state.abort_bot_collision
          end

          def personal_best_path
            @paths[:p_best]
          end

          def global_best_path
            @paths[:g_best]
          end

          def update_global_best
            all_paths = @bot.outer_data
                            .filter(&:path?)
                            .map { |data| Path::Path.new(@collision_mapping, **data.content) }
                            .reject(&:empty?)

            return if all_paths.empty?

            @paths[:g_best] = all_paths.max_by do |path|
              path.found_target? ? 100 + (100.0 / (1 + path.path_length)) : path.calculate_score(@target_nest)
            end
          end

          def personal_best(path)
            @paths[:p_best] = path
            store_path_data
          end

          def update_personal_best(path = paths[:current])
            return if !@paths[:p_best].empty? && @paths[:p_best].compare(path, @target_nest).negative?

            @paths[:p_best] = path
            store_path_data
          end

          def explore_target(path, on_path_update)
            @state = PsoState::ExplorationState.new(self, path, on_path_update, { x: @target_nest.x, y: @target_nest.y })
          end

          def recollect(path, on_path_update, target, recollection_segment: nil)
            @state = PsoState::RecollectionState.new(self, path, on_path_update, target, recollection_segment: recollection_segment)
          end

          def wants_trophallaxis?(other_bot)
            return true unless other_bot.is_a?(Bot)

            !(@bot.energy <= Constants::Bot::MAX_ENERGY_LEVEL * 0.4 && other_bot.energy <= Constants::Bot::MAX_ENERGY_LEVEL * 0.4) &&
              (@bot.energy - other_bot.energy).abs >= Constants::Bot::MAX_ENERGY_LEVEL * 0.08 &&
              rand < Constants::Bot::ENERGY_FACTOR.call(@bot.energy) * (1 - selfishness + 0.05)
          end

          private

          def generate_fallback_path
            path = Path::Path.new(@collision_mapping)

            path.add_segment(x: @start_nest.x, y: @start_nest.y)
            path.add_segment(x: x, y: y)
            path
          end

          def store_path_data
            @bot.add_data_bundle(@paths[:p_best].to_data_bundle)
          end

          def prioritize_targets(p_best, g_best)
            p_has = p_best.found_target?
            g_has = g_best.found_target?

            return p_best if p_has && !g_has
            return g_best if !p_has && g_has

            p_length = p_best.path_length * selfishness
            g_length = g_best.path_length * (1 - selfishness)
            p_length < g_length ? p_best : g_best
          end

          def either_has_target?(*paths)
            paths.any?(&:found_target?)
          end
        end
      end
    end
  end
end
