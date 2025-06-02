# frozen_string_literal: true

module Simulation
  class SimulationConfig
    include Util

    attr_reader :name, :width, :height, :objects

    def initialize(path, map_path, width: nil, height: nil)
      base_config = load_config(path)
      map_config = load_config(map_path)

      strategy = base_config.delete(:strategy)
      map_config[:bots].each { |bot| bot[:strategy] = strategy }

      @config = map_config
      @width = width || @config[:width]
      @height = height || @config[:height]
      @name = "#{File.basename(path, File.extname(path))}-#{File.basename(map_path, File.extname(map_path))}"
      @data_bundles = []
      @objects = {
        bots: create_bots,
        obstacles: create_obstacles,
        station: create_station(:station),
        target_station: create_station(:target_station),
      }
    end

    def bots
      @objects[:bots]
    end

    def obstacles
      @objects[:obstacles]
    end

    def station
      @objects[:station]
    end

    def target_station
      @objects[:target_station]
    end

    private

    def load_config(file_path)
      deep_transform_keys(JSON.parse(File.read(file_path)), &:to_sym)
    end

    def create_bots
      @config[:bots].map do |bot_config|
        graphics_config = init_image(bot_config)
        strategy_clazz = Simulation::Object::Bot::Strategy.const_get(bot_config[:strategy])
        data_bundles = init_data(bot_config)
        start = {
          x: @config[:station][:x],
          y: @config[:station][:y],
        }
        target = {
          x: @config[:target_station][:x],
          y: @config[:target_station][:y],
        }

        graphics_config.merge!(strategy: strategy_clazz, data: data_bundles, target: target, start: start)
      end
    end

    def create_obstacles
      (@config[:obstacles] + create_borders).map { |obstacle_config| init_image(obstacle_config) }
    end

    def create_station(path)
      data_config = @config[path]
      graphics_config = init_image(data_config)
      data_bundles = init_data(data_config)

      graphics_config.merge!(data: data_bundles)
    end

    def create_borders
      [
        { x: 0, y: 0, mass: 500, width: 10, height: @height, rotation: 0 },
        { x: @width - 10, y: 0, mass: 500, width: 10, height: @height, rotation: 0 },
        { x: 0, y: 0, mass: 500, width: @width, height: 10, rotation: 0 },
        { x: 0, y: @height - 10, mass: 500, width: @width, height: 10, rotation: 0 },
      ]
    end

    def init_image(config)
      {
        location: Physics::Vector.new(config[:x], config[:y]),
        mass: config[:mass],
        width: config[:width],
        height: config[:height],
        rotation: config[:rotation] || 0,
      }
    end

    def init_data(config)
      return [] unless config[:data]

      data_bundle = config[:data]
      @data_bundles.find { |db| db == data_bundle } || @data_bundles.push(data_bundle).last
      [data_bundle]
    end
  end
end
