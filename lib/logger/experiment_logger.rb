# frozen_string_literal: true

module Logger
  class ExperimentLogger
    HEADERS = %w[iteration tick data type].freeze

    def initialize(file_name)
      @logs_dir = File.expand_path("../../experiments/#{file_name}", __dir__)
      FileUtils.mkdir_p(@logs_dir)

      csv_file_path = File.join(@logs_dir, 'data.csv')
      @csv = CSV.open(csv_file_path, 'w')
      @csv << HEADERS

      log_file_path = File.join(@logs_dir, 'info.json')
      @log_file = File.open(log_file_path, 'w')
      @log_file.puts('[')
    end

    def log_data(iteration, tick, target_station, type)
      @csv << [
        iteration,
        tick,
        target_station.data.filter(&:generic?).map(&:content).uniq.join(', '),
        type,
      ]
    end

    def log_message(message, last: false)
      @log_file.puts(message.to_json.to_s)
      @log_file.print(',') unless last
    end

    def close
      @log_file.puts(']')
      @log_file.close
    end
  end
end
