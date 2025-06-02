# frozen_string_literal: true

module KdTree
  class Node
    attr_accessor :left, :right, :object

    def initialize(object)
      @left = nil
      @right = nil
      @object = object
    end

    def x
      @object.center.x
    end

    def y
      @object.center.y
    end
  end
end
