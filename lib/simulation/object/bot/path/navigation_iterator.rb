# frozen_string_literal: true

module Simulation
  module Object
    module Bot
      module Path
        class NavigationIterator
          def initialize(path:, segments:, current_index: 0, reversed: false)
            @path = path
            @reversed = reversed
            @original_segments = segments.dup
            @segments = @reversed ? @original_segments.reverse : @original_segments
            current_index = current_index.clamp(0, @segments.size - 1)
            @current_index = @reversed ? @segments.count - current_index : current_index
            @previous_index = @current_index

            @skipped_segments = []
            @new_skipped_segments = []
            @skip_failed = false
          end

          def apply_skip
            return unless should_apply_skip?
            return if @segments.size <= 3

            old_start_idx = @original_segments.index(@skipped_segments.first).clamp(1, @segments.size - 2)
            old_end_idx = @original_segments.index(@skipped_segments.last).clamp(1, @segments.size - 2)
            return unless old_start_idx && old_end_idx
            return if old_start_idx >= old_end_idx

            @original_segments[old_start_idx..old_end_idx] = @reversed ? @new_skipped_segments.reverse : @new_skipped_segments
            @path.change_path(@original_segments)

            update_navigation_position

            @skipped_segments.clear
            @new_skipped_segments.clear
          end

          def skip_failed
            @current_index = @previous_index
            @skipped_segments.clear
            @new_skipped_segments.clear
            @skip_failed = true
          end

          def next(skip: 0)
            if @skip_failed
              skip = 0
              @skip_failed = false
            end
            return nil if reached_end?

            apply_skip_if_needed

            move_to_next_segment(skip)
            current_segment
          end

          def last_segment
            @segments.last
          end

          def traversed_segments
            return @original_segments[0..@current_index] unless @reversed

            new_index = @original_segments.index(@segments[@current_index])
            @original_segments[0..new_index]
          end

          def record_skipped_segment(segment)
            @new_skipped_segments << segment
          end

          def previous_segment
            @segments[@previous_index]
          end

          def current_segment
            return @segments.first if @segments.size <= 1

            @segments[@current_index.clamp(0, @segments.size - 1)]
          end

          def reached_end?
            @current_index >= @segments.size - 1
          end

          private

          def apply_skip_if_needed
            apply_skip if @skipped_segments.size > 1
            @skipped_segments.clear
            @new_skipped_segments.clear
          end

          def move_to_next_segment(skip)
            @previous_index = @current_index
            new_index = (@current_index + 1 + skip).clamp(0, @segments.size - 1)
            skipped = @segments[(@current_index)..new_index] || []
            @skipped_segments = @reversed ? skipped.reverse : skipped
            @current_index = new_index
          end

          def should_apply_skip?
            return false if @new_skipped_segments.empty? || @skipped_segments.empty?

            new_length = calculate_segment_length(@new_skipped_segments)
            old_length = calculate_segment_length(@skipped_segments)
            new_length < old_length
          end

          def calculate_segment_length(segments)
            segments.each_cons(2).sum { |a, b| Math.hypot(b[:x] - a[:x], b[:y] - a[:y]) }
          end

          def update_navigation_position
            delta = @new_skipped_segments.size - 1

            new_index = @current_index + delta
            @segments = @reversed ? @original_segments.reverse : @original_segments
            @current_index = new_index.clamp(0, @segments.size - 1)
          end
        end
      end
    end
  end
end
