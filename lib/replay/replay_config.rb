# frozen_string_literal: true

module Replay
  class ReplayConfig
    attr_reader :width, :height

    include Util

    def initialize(path, width: nil, height: nil, bot_ids: nil)
      simulation_config = extract_simulation_config(path)
      @log_file = CSV.open(path, 'r')
      @width = width || simulation_config.width
      @height = height || simulation_config.height
      @objects = parse_log_file(simulation_config, bot_ids)
      @initial_energy = @objects[0].map(&:energy).reduce(:+)
    end

    def energy
      tick = Simulation::TickCounter.tick
      return 0 unless @objects[tick]

      @objects[tick].map(&:energy).reduce(:+) / @initial_energy
    end

    def objects(tick)
      @objects[tick]
    end

    private

    def extract_simulation_config(log_file)
      config_path = "configurations/#{log_file.split('/').last.split('-').first}.json"
      map_path = "configurations/maps/#{log_file.split('/').last.split('-')[1]}.json"
      Simulation::SimulationConfig.new(config_path, map_path)
    end

    def parse_log_file(simulation_config, bot_ids)
      objects = Hash.new { |hash, key| hash[key] = [] }
      last_bot_id = -1

      @log_file.each.with_index do |line, index|
        next if index.zero?

        id = line[1].to_i
        next if bot_ids && !bot_ids.include?(id)

        type = line[11].to_sym

        replay_object = case type
                        when :bot
                          last_bot_id = id
                          parse_bot(id, line, simulation_config)
                        when :station
                          parse_station(id, line, simulation_config)
                        when :target_station
                          parse_target_station(id, line, simulation_config)
                        else
                          raise "Unknown object type: #{type}"
                        end

        objects[line[0].to_i] << replay_object
      end

      simulation_config.obstacles.each do |obstacle|
        last_bot_id += 1
        objects[0] << parse_obstacle(last_bot_id, obstacle)
      end

      objects
    end

    def parse_bot(id, line, simulation_config)
      location = Physics::Vector.new(line[4].to_f, line[5].to_f)
      rotation = line[8].to_f

      mass = simulation_config.bots[id][:mass]
      width = simulation_config.bots[id][:width]
      height = simulation_config.bots[id][:height]

      ReplayObject.new(
        Physics::Shape::Image.new(location, mass, width, height, rotation, 'sprites/bot.png'),
        id,
        line[2].to_f,
        line[3].split(',').map(&:to_i),
        line[6].to_f,
        line[7].to_f,
        line[9].to_sym,
        line[10].split('|').map(&:to_f),
        line[11].to_sym,
      )
    end

    def parse_station(id, line, simulation_config)
      location = simulation_config.station[:location]
      mass = simulation_config.station[:mass]
      width = simulation_config.station[:width]
      height = simulation_config.station[:height]
      rotation = simulation_config.station[:rotation]

      ReplayObject.new(
        Physics::Shape::Image.new(location, mass, width, height, rotation, 'sprites/white_rect.png'),
        id,
        line[2].to_f,
        line[3].split(',').map(&:to_i),
        line[6].to_f,
        line[7].to_f,
        line[9].to_sym,
        line[10].split('|').map(&:to_f),
        line[11].to_sym,
      )
    end

    def parse_target_station(id, line, simulation_config)
      location = simulation_config.target_station[:location]
      mass = simulation_config.target_station[:mass]
      width = simulation_config.target_station[:width]
      height = simulation_config.target_station[:height]
      rotation = simulation_config.target_station[:rotation]
      data = line[3].split(',').map(&:to_i)

      ReplayObject.new(
        Physics::Shape::Image.new(location, mass, width, height, rotation, 'sprites/white_rect.png'),
        id,
        0,
        data,
        0,
        0,
        :active,
        [1, 0.7, 0, 1],
        :target_station,
      )
    end

    def parse_obstacle(id, obstacle)
      location = obstacle[:location]
      mass = obstacle[:mass]
      width = obstacle[:width]
      height = obstacle[:height]

      ReplayObject.new(
        Physics::Shape::Rectangle.new(location, mass, width, height),
        id,
        0,
        [],
        0,
        0,
        :none,
        [0.67, 0.67, 0.67, 1],
        :obstacle,
      )
    end
  end
end
