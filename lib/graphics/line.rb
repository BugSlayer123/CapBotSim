# frozen_string_literal: true

module Graphics
  class Line
    def initialize(window, x1, y1, x2, y2, width, color, layer = -1)
      @ruby2d_line = Ruby2D::Line.new(
        x1: x1, y1: y1,
        x2: x2, y2: y2,
        width: width,
        color: color,
        z: layer
      )
      @window = window
      window.add(@ruby2d_line)
    end

    def update(x1, y1, x2, y2)
      @ruby2d_line.x1 = x1
      @ruby2d_line.y1 = y1
      @ruby2d_line.x2 = x2
      @ruby2d_line.y2 = y2
    end

    def remove
      @window.remove(@ruby2d_line)
    end
  end
end
