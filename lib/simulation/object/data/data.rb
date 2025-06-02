# frozen_string_literal: true

module Simulation
  module Object
    module Data
      class Data
        attr_reader :id, :content, :type

        def initialize(owner, content)
          @id = owner.id
          @content = content
          @type = determine_type(content)
        end

        def path?
          @type == :path
        end

        def generic?
          @type == :generic
        end

        def to_hash
          {
            id: @id,
            type: @type,
            content: @content,
          }
        end

        private

        def determine_type(content)
          content.is_a?(Hash) && path_keys?(content) ? :path : :generic
        end

        def path_keys?(content)
          %i[segments].any? { |k| content.key?(k) }
        end
      end
    end
  end
end
