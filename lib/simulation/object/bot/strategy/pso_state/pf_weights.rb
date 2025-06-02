# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Strategy
        module PsoState
          class PfWeights
            attr_reader :selfishness, :attractive_weight, :repulsive_weight, :repulsive_exp, :social_weight, :social_exp

            def initialize(id)
              @selfishness = rand

              a = Constants::Strategy::Pso::PotentialFields::ATTRACTIVE_FORCE_WEIGHT
              @attractive_weight = rand(a[0]..a[1])

              r = Constants::Strategy::Pso::PotentialFields::REPULSIVE_FORCE_WEIGHT
              r_exp = Constants::Strategy::Pso::PotentialFields::REPULSIVE_FORCE_EXP
              @repulsive_weight = rand(r[0]..r[1])
              @repulsive_exp = rand(r_exp[0]..r_exp[1])

              s = Constants::Strategy::Pso::PotentialFields::SOCIAL_FORCE_WEIGHT
              s_exp = Constants::Strategy::Pso::PotentialFields::SOCIAL_FORCE_EXP
              @social_weight = rand(s[0]..s[1])
              @social_exp = rand(s_exp[0]..s_exp[1])

              pp "#{id}: #{@selfishness.round(2)}, attr: #{@attractive_weight.round(2)}, rep: #{@repulsive_weight.round(2)}, soc: #{@social_weight.round(2)}, rep_exp: #{@repulsive_exp.round(2)}, soc_exp: #{@social_exp.round(2)}" if Constants::Simulation::DEBUG
            end

            def max_attractive
              Constants::Strategy::Pso::PotentialFields::MAX_ATTRACTIVE.call(@attractive_weight)
            end

            def max_repulsive
              Constants::Strategy::Pso::PotentialFields::MAX_REPULSIVE.call(@repulsive_weight)
            end

            def max_social
              Constants::Strategy::Pso::PotentialFields::MAX_SOCIAL.call(@social_weight)
            end

            def max_force
              Constants::Strategy::Pso::PotentialFields::MAX_FORCE.call(max_attractive, max_repulsive, max_social)
            end

            def force_normalization
              Constants::Strategy::Pso::PotentialFields::FORCE_NORMALIZATION.call(max_force)
            end

            def repulsion_base
              Constants::Strategy::Pso::PotentialFields::REPULSION_BASE.call(max_force, @repulsive_exp)
            end

            def social_base
              Constants::Strategy::Pso::PotentialFields::SOCIAL_BASE.call(max_force, @social_exp)
            end
          end
        end
      end
    end
  end
end
