# frozen_string_literal: true

module Graphics
  class Object
    attr_reader :size

    def initialize(window, object, text: '')
      @object = object
      @ruby2d_shape = @object.create_ruby2d_shape
      @size = @object.height / 1.5

      @text = Text.new(text, x: 0, y: 0, size: @size, color: 'white', font: 'Roboto-Regular.ttf')

      window.add(@ruby2d_shape)
      window.add(@text)

      render
    end

    def render(text: nil)
      @ruby2d_shape.x = @location&.x || @object.location.x
      @ruby2d_shape.y = @location&.y || @object.location.y

      @ruby2d_shape.rotate = @rotation || @object.rotation if @ruby2d_shape.instance_of?(Ruby2D::Image)

      @text.x = @object.center.x - (@text.width / 2)
      @text.y = @object.center.y - (@text.height / 2)

      @ruby2d_shape.color = @object.color

      @text.text = text if text
    end

    def update_location(new_location, new_rotation = nil)
      @location = new_location
      @rotation = new_rotation
    end
  end
end
