# frozen_string_literal: true

module Graphics
  class GraphicsManager
    def initialize(objects, energy_f, width, height, tick_method, left_click_handler: nil)
      @objects = objects
      @width = width
      @height = height
      @tick = tick_method
      @left_click_handler = left_click_handler
      @path_lines = {
        current: [],
        personal_best: [],
        global_best: [],
        best: [],
      }

      @tick_counter = Text.new(Simulation::TickCounter.tick, x: width - 200, y: 0, size: 50, color: 'black', font: 'Roboto-Regular.ttf')
      @energy_f = energy_f
      @energy_counter = Text.new(energy_f.call.round(2), x: width - 200, y: 100, size: 50, color: 'black', font: 'Roboto-Regular.ttf')
      @graphics_objects = {}

      init_window
      init_listeners
    end

    def start
      @window.add(@tick_counter)
      @window.add(@energy_counter)
      @window.show
    end

    def display(objects: nil, update_locations: false)
      (objects || @objects).each do |object|
        graphics_object = @graphics_objects[object.id] ||= Graphics::Object.new(@window, object)
        graphics_object.update_location(object.location, object.rotation) if update_locations

        text = object.id.to_s if Constants::Simulation::DISPLAY_ID && object.instance_of?(Simulation::Object::Bot::Bot)
        graphics_object.render(text: text)
      end

      @tick_counter.text = "#{(Simulation::TickCounter.tick / 3600).to_i}:#{(Simulation::TickCounter.tick % 3600 / 60).to_i.to_s.rjust(2, '0')}"
      return unless (Simulation::TickCounter.tick % 1800).zero?

      @energy_counter.text = "#{(@energy_f.call * 100).round(1)}%"
    end

    def enable_path(bot)
      return unless bot.instance_of?(Simulation::Object::Bot::Bot)

      @bot = bot
    end

    def show_paths
      return if @bot.nil? || !@bot.strategy.instance_of?(Simulation::Object::Bot::Strategy::Pso)

      show_path(:current, @bot.paths[:current].segments, 4, 'yellow', -4) if @bot.paths[:current]&.segments&.any?
      show_path(:personal_best, @bot.personal_best_path.segments, 4, Constants::Simulation::PERSONAL_BEST_COLOR, Constants::Simulation::PERSONAL_BEST_PATH_LAYER) if @bot.personal_best_path&.segments&.any?
      show_path(:global_best, @bot.global_best_path.segments, 4, Constants::Simulation::GLOBAL_BEST_COLOR, Constants::Simulation::GLOBAL_BEST_PATH_LAYER) if @bot.global_best_path&.segments&.any?
      show_path(:best, @bot.best_path.first.segments, 1, Constants::Simulation::BEST_COLOR, Constants::Simulation::BEST_PATH_LAYER) if @bot.best_path&.first&.segments&.any?
    end

    def clear_path
      @path_lines.each_value do |lines|
        lines.each(&:remove)
        lines.clear
      end
      @bot = nil
    end

    private

    def show_path(type, segments, width, color, layer = -1)
      segments.each_cons(2).with_index do |(start_seg, end_seg), i|
        if (line = @path_lines[type][i])
          line.update(
            start_seg[:x], start_seg[:y],
            end_seg[:x], end_seg[:y]
          )
        else
          @path_lines[type] << Graphics::Line.new(
            @window,
            start_seg[:x], start_seg[:y],
            end_seg[:x], end_seg[:y],
            width, color, layer
          )
        end
      end

      return unless @path_lines[type].size > (segments.size - 1)

      @path_lines[type].pop(@path_lines[type].size - (segments.size - 1)).each(&:remove)
    end

    def init_window
      @window = Ruby2D::Window.new
      @window.set(
        title: 'Capbot Simulation',
        width: @width,
        height: @height,
        background: 'white',
        resizable: false,
        fullscreen: false,
        borderless: true,
      )
    end

    def init_listeners
      @window.on(:mouse_down) { |event| handle_mouse_event(event) }
      @window.update { @tick.call }
    end

    def handle_mouse_event(event)
      position = Physics::Vector.new(event.x, event.y)

      case event.button
      when :left
        handle_left_click(position)
      when :right
        # handle_right_click(position)
      end
    end

    def handle_left_click(position)
      @left_click_handler&.call(position)
    end
  end
end
