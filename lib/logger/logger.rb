# frozen_string_literal: true

module Logger
  class Logger
    def enable_logs(bot)
      @bot = bot
    end

    def disable_logs
      @bot = nil
      @logs = nil
    end

    def show_logs
      update_logs

      return if @logs.nil? || @logs.empty?

      puts "#{@logs}\n"
    end

    private

    def update_logs
      return if @bot.nil? || !@bot.is_a?(Simulation::Object::Bot::Bot)

      id = @bot.id
      velocity = @bot.velocity.magnitude.round(4)
      energy = @bot.energy.round
      data = @bot.data.length
      status = @bot.status

      return unless Constants::Simulation::SHOW_LOGS

      @logs = <<~LOGS
        +--------+----------+--------+------+--------+
        | Bot ID | Velocity | Energy | Data | Status |
        +--------+----------+--------+------+--------+
        | #{format('%-6s', id)} | #{format('%-8s', velocity)} | #{format('%-6s', energy)} | #{format('%-4s', data)} | #{format('%-6s', status)} |
        +--------+----------+--------+------+--------+
      LOGS
    end
  end
end
