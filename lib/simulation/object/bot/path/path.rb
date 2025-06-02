# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Path
        class Path
          extend Forwardable
          include Util
          attr_reader :id, :segments
          attr_accessor :on_path_change

          def_delegators :@navigation_iterator, :next, :previous, :current_segment, :previous_segment, :last_segment, :refresh, :skip_failed, :reached_end?, :record_skipped_segment, :traversed_segments

          def initialize(collision_mapping, segments: [], on_path_change: -> {})
            @collision_mapping = collision_mapping
            @id = SecureRandom.uuid
            @segments = segments
            @on_path_change = on_path_change
          end

          def compare(other, target, selfishness = 0.5)
            self_score = calculate_score(target)
            other_score = other.calculate_score(target)

            return -1 if self_score == 100 && other_score != 100
            return 1 if other_score == 100 && self_score != 100

            if self_score == 100 && other_score == 100
              self_weight = path_length * (1 - selfishness)
              other_weight = other.path_length * selfishness
              self_weight <=> other_weight
            else
              (self_score * selfishness) <=> (other_score * (1 - selfishness))
            end
          end

          def calculate_score(target)
            if found_target?
              100
            else
              last = segments.last
              current_position = Physics::Vector.new(last[:x], last[:y])
              distance = current_position.distance(other: target)

              distance_score = Constants::Strategy::Pso::Weights::DISTANCE / (1 + distance)
              length_score = Constants::Strategy::Pso::Weights::LENGTH * Math.log(1 + path_length)
              collision_score = Constants::Strategy::Pso::Weights::COLLISIONS * bot_collisions(CapBotSimulation.seconds_passed).length / 20

              total = distance_score + length_score + collision_score

              [total, 99].min.round # target more important
            end
          end

          def change_path(new_segments)
            @segments = new_segments
            notify_path_change
          end

          def add_segment(x:, y:, collision: false, bot_collision: false, seconds: nil)
            segment = { x: x, y: y, collision: collision, bot_collision: bot_collision }
            @segments << segment

            @collision_mapping.add_static_obstacle(x, y) if collision

            if bot_collision
              ttl = seconds || Constants::Strategy::Pso::Exploration::BOT_COLLISION_TIME_TO_LIVE
              @collision_mapping.add_bot_collision(x, y, ttl)
            end

            @on_path_change.call
          end

          def add_found_station(station)
            station.is_a?(Obstacle::TargetStation) ? create_target_station_segment(station) : create_station_segment(station)
          end

          def found_target?
            end_nest&.key?(:target)
          end

          def empty?
            segments.empty?
          end

          def path_length
            segments.each_cons(2).sum { |a, b| distance_between(a, b) }
          end

          def obstacles
            @collision_mapping.static_obstacles
          end

          def bot_collisions(current_time)
            @collision_mapping.bot_collisions(current_time)
          end

          def navigate_to(current_x, current_y, target: :end_nest, current_segment: nil)
            reversed = target == :start_nest
            current_segment ||= find_nearest_segment(current_x, current_y)
            start_index = @segments.index(current_segment) || 0

            @navigation_iterator = NavigationIterator.new(
              path: self,
              segments: @segments,
              current_index: start_index,
              reversed: reversed,
            )
          end

          def finish_navigation
            @navigation_iterator&.apply_skip
            # @navigation_iterator = nil
          end

          def clone
            self.class.new(@collision_mapping, segments: segments.dup, on_path_change: @on_path_change)
          end

          def to_data_bundle
            { segments: segments.dup }
          end

          private

          def end_nest
            segments.last
          end

          def notify_path_change
            @on_path_change&.call
          end

          def create_target_station_segment(station)
            @segments << { x: station.location.x, y: station.location.y, station: true, target: true }
          end

          def create_station_segment(station)
            @segments << { x: station.location.x, y: station.location.y, station: true }
          end

          def find_nearest_segment(x, y)
            segments.min_by { |s| distance_between(s, { x: x, y: y }) }
          end
        end
      end
    end
  end
end
