# frozen_string_literal: true

module Simulation
  module Object
    class ObjectManager
      attr_reader :objects, :bots, :station, :target_station

      def initialize(bots, obstacles, station, target_station)
        @bots = create_objects(bots, Bot::Bot)
        @obstacles = create_objects(obstacles, Obstacle::Obstacle, @bots.size)
        @station = create_object(station, Obstacle::Station, @bots.size + @obstacles.size)
        @target_station = create_object(target_station, Obstacle::TargetStation, @bots.size + @obstacles.size + 1)

        @objects = KdTree::Kdtree.new(@bots + @obstacles + [@station, @target_station])
        @collision_manager = Physics::CollisionManager.new(@bots, @objects)
        @initial_energy = @bots.map(&:energy).reduce(:+)
      end

      def energy
        @bots.map(&:energy).reduce(:+) / @initial_energy
      end

      def tick(second_passed)
        @objects.update_positions if second_passed

        collisions = @collision_manager.handle_collisions
        lookup = @objects.each_with_object({}) { |o, hash| hash[o.id] = o }
        @bots.each do |bot|
          collided_ids = collisions[bot.id] || []
          collided_objects = collided_ids.map { |id| lookup[id] }.compact

          bot.tick(second_passed, collided_objects)
        end
      end

      def get_object_at(position)
        @collision_manager.get_object_at(position)
      end

      private

      def create_objects(configs, clazz, start_id = 0)
        configs.map.with_index { |config, index| clazz.new(start_id + index, *config.values) }
      end

      def create_object(config, clazz, id)
        clazz.new(id, *config.values)
      end
    end
  end
end
