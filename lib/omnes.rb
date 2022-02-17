# frozen_string_literal: true

require 'omnes/version'
require 'omnes/bus'

module Omnes
  def self.included(klass)
    bus = Bus.new
    klass.define_method(:omnes_bus) { bus }
    Bus.instance_methods(false).each do |method|
      klass.define_method(method) do |*args, **kwargs, &block|
        omnes_bus.send(method, *args, **kwargs, &block)
      end
    end
  end
end
