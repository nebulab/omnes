# frozen_string_literal: true

require "omnes/bus"
require "omnes/event"
require "omnes/subscriber"
require "omnes/version"

# Pub/sub bus behavior
#
# Include this module to have a class work as an {Omnes::Bus}.
module Omnes
  # Shortcut to access components configuration
  #
  # @return [Omnes::Config]
  def self.config
    Config
  end

  # Wrapper for components configuration
  module Config
    # {Omnes::Subscriber} configuration
    #
    # @return [Dry::Configurable::Config]
    def self.subscriber
      Omnes::Subscriber.config
    end

    # {Omnes::Event} configuration
    #
    # @return [Dry::Configurable::Config]
    def self.event
      Omnes::Event.config
    end
  end

  def self.included(klass)
    bus = Bus.new(caller_location_start: 2)
    klass.define_method(:omnes_bus) { bus }
    Bus.instance_methods(false).each do |method|
      klass.define_method(method) do |*args, **kwargs, &block|
        omnes_bus.send(method, *args, **kwargs, &block)
      end
    end
  end
end
