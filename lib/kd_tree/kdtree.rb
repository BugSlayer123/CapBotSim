# frozen_string_literal: true

module KdTree
  class Kdtree
    def initialize(objects)
      @nodes = objects.map { |o| Node.new(o) }
      @root = build_tree(@nodes, 0)

      @count = 0
    end

    def all_objects
      @nodes.map(&:object)
    end

    def count
      @nodes.count
    end

    def update_positions
      @root = build_tree(@nodes, 0)
    end

    def <<(object)
      new_node = Node.new(object)
      @nodes.push(new_node)
      @root = build_tree(@nodes, 0)
    end

    def each(&)
      return enum_for(:each) unless block_given?

      iterate(@root, &)
    end

    def each_with_object(object)
      return enum_for(:each_with_object, object) unless block_given?

      each { |node| yield(node, object) }
      object
    end

    def all_collisions(object)
      search_kd_tree_for_collisions(@nodes.find { |node| node.object == object }, @root, 0)
        .map(&:object)
    end

    def nearby_nodes_at_position(position, radius)
      search_kd_tree_with_position(position, @root, radius, 0)
        .map(&:object)
    end

    def size
      @nodes.size
    end

    private

    def build_tree(nodes, depth)
      return nil if nodes.empty?

      axis = depth % 2 # even: x-axis, oneven: y-axis
      sorted_nodes = nodes.sort_by { |node| axis.zero? ? node.x : node.y }
      median = sorted_nodes.length / 2
      median_node = sorted_nodes[median]

      median_node.left = build_tree(sorted_nodes[0...median], depth + 1)
      median_node.right = build_tree(sorted_nodes[(median + 1)..], depth + 1)

      median_node
    end

    def search_kd_tree_with_position(position, node, radius, depth)
      return [] if node.nil?

      nearby = []

      axis = depth % 2
      nearby.push(node) if Math.sqrt(((position.x - node.x)**2) + ((position.y - node.y)**2)) <= radius

      if axis.zero?
        if position.x < node.x
          nearby += search_kd_tree_with_position(position, node.left, radius, depth + 1)
          nearby += search_kd_tree_with_position(position, node.right, radius, depth + 1) if (node.x - position.x).abs <= radius
        else
          nearby += search_kd_tree_with_position(position, node.right, radius, depth + 1)
          nearby += search_kd_tree_with_position(position, node.left, radius, depth + 1) if (node.x - position.x).abs <= radius
        end
      elsif position.y < node.y
        nearby += search_kd_tree_with_position(position, node.left, radius, depth + 1)
        nearby += search_kd_tree_with_position(position, node.right, radius, depth + 1) if (node.y - position.y).abs <= radius
      else
        nearby += search_kd_tree_with_position(position, node.right, radius, depth + 1)
        nearby += search_kd_tree_with_position(position, node.left, radius, depth + 1) if (node.y - position.y).abs <= radius
      end

      nearby
    end

    def search_kd_tree_for_collisions(compare_node, node, depth)
      return [] if node.nil?

      nearby = []

      axis = depth % 2
      nearby.push(node) if node != compare_node && compare_node.object.overlap?(node.object.shape)

      if axis.zero?
        if compare_node.x < node.x
          nearby += search_kd_tree_for_collisions(compare_node, node.left, depth + 1)
          nearby += search_kd_tree_for_collisions(compare_node, node.right, depth + 1) if (node.x - compare_node.x).abs <= (node.object.width + compare_node.object.width) / 2
        else
          nearby += search_kd_tree_for_collisions(compare_node, node.right, depth + 1)
          nearby += search_kd_tree_for_collisions(compare_node, node.left, depth + 1) if (node.x - compare_node.x).abs <= (node.object.width + compare_node.object.width) / 2
        end
      elsif compare_node.y < node.y
        nearby += search_kd_tree_for_collisions(compare_node, node.left, depth + 1)
        nearby += search_kd_tree_for_collisions(compare_node, node.right, depth + 1) if (node.y - compare_node.y).abs <= (node.object.height + compare_node.object.height) / 2
      else
        nearby += search_kd_tree_for_collisions(compare_node, node.right, depth + 1)
        nearby += search_kd_tree_for_collisions(compare_node, node.left, depth + 1) if (node.y - compare_node.y).abs <= (node.object.height + compare_node.object.height) / 2
      end

      nearby
    end

    def iterate(node, &block)
      return if node.nil?

      iterate(node.left, &block)
      block.call(node.object)
      iterate(node.right, &block)
    end
  end
end
