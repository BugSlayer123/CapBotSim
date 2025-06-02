# frozen_string_literal: true

module Logger
  class CsvLogger
    def initialize(file_name)
      @logs_dir = File.expand_path('../../logs', __dir__)
      @file_path = File.join(@logs_dir, file_name)

      FileUtils.mkdir_p(@logs_dir)

      CSV.open(@file_path, 'w') do |csv|
        csv << %w[tick bot_id energy data x y vel_x vel_y rotation status color type]
      end
    end

    def log(tick, bots, station = nil, target_station = nil)
      CSV.open(@file_path, 'a') do |csv|
        bots.each do |bot|
          csv << [
            tick,
            bot.id,
            bot.energy,
            bot.data.filter(&:generic?).map(&:content).uniq.join(', '),
            bot.location.x.round(4),
            bot.location.y.round(4),
            bot.velocity.x.round(4),
            bot.velocity.y.round(4),
            bot.rotation,
            bot.status,
            bot.color.join('|'),
            'bot',
          ]
        end

        if station
          csv << [
            tick,
            station.id,
            0,
            station.data.filter(&:generic?).map(&:content).uniq.join(', '),
            station.location.x.round(4),
            station.location.y.round(4),
            0,
            0,
            0,
            station.status,
            station.color.join('|'),
            'station',
          ]
        end

        if target_station
          csv << [
            tick,
            target_station.id,
            0,
            target_station.data.filter(&:generic?).map(&:content).uniq.join(', '),
            target_station.location.x.round(4),
            target_station.location.y.round(4),
            0,
            0,
            0,
            target_station.status,
            target_station.color.join('|'),
            'target_station',
          ]
        end
      end
    end
  end
end
