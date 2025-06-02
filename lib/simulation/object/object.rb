# frozen_string_literal: true

module Simulation
  module Object
    class Object
      extend Forwardable
      attr_reader :id, :size, :shape
      attr_accessor :status

      def_delegators :@shape, :location, :overlap?, :width, :height, :mass,
                     :create_ruby2d_shape, :change_location, :center,
                     :corrected_overlap_locations, :radius, :rotate,
                     :rotation, :intersection, :bounding_box, :move_by, :rotated?, :axes, :project, :rotation=

      def initialize(id, data = [])
        @id = id
        @data = {}
        @status = :active

        data.each { |d| add_data_bundle(d) }
      end

      def color
        [0, 0, 0, 0]
      end

      def handles_collisions?
        false
      end

      def add_data(data)
        data.each do |data_obj|
          next if @id == data_obj.id

          @data[data_obj.id] = data_obj
        end
      end

      def add_data_bundle(data_bundle, owner = self)
        data_obj = if data_bundle.is_a?(Data::Data)
                     data_bundle
                   else
                     Data::Data.new(owner, data_bundle)
                   end

        @data[data_obj.id] = data_obj
      end

      def data
        @data.values
      end

      def outer_data
        @data.reject { |k, _| k == @id }.values
      end
    end
  end
end
