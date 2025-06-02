# frozen_string_literal: true

module Physics
  class CollisionManager
    DEBOUNCE_TIME = 0.5

    def initialize(bots, objects)
      @bots = bots
      @objects = objects
      @last_collision_time = {}
    end

    def handle_collisions
      collisions = Hash.new { |hash, key| hash[key] = Set.new }
      @objects.each do |bot|
        detect_collisions_for(bot, collisions)
          .each { |other_object| correct_overlap(bot, other_object) }
      end
      collisions.delete_if { |_key, value| value.empty? }
    end

    private

    def correct_overlap(object, other_object)
      location1, location2 = object.corrected_overlap_locations(other_object.shape)
      object.change_location(location1)
      other_object.change_location(location2)
    end

    def detect_collisions_for(object, collisions)
      kd_collisions = @objects.all_collisions(object)
      kd_collisions.reject { |other_object| already_recorded?(object, other_object, collisions) || (!object.handles_collisions? && !other_object.handles_collisions?) }
                   .each { |other_object| record_collision(object, other_object, collisions) }
    end

    def already_recorded?(object, other_object, collisions)
      collisions[object.id].include?(other_object.id) || collisions[other_object.id].include?(object.id)
    end

    def record_collision(object1, object2, collisions)
      store_collision(object1.id, object2.id, collisions) if object1.handles_collisions?
      store_collision(object2.id, object1.id, collisions) if object2.handles_collisions?
    end

    def store_collision(recorder_id, target_id, collisions)
      collisions[recorder_id].add(target_id)
      @last_collision_time[[recorder_id, target_id]] = Time.now
    end
  end
end
