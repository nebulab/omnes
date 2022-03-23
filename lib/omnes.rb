# frozen_string_literal: true

require "omnes/bus"
require "omnes/event"
require "omnes/subscriber"
require "omnes/version"

# Pub/sub library for Ruby.
#
# There're two ways to make use of the pub/sub features Omnes provides:
#
# - Standalone, through an {Omnes::Bus} instance.
# - Mixing in the behavior in another class by including the {Omnes} module.
#
# Refer to {Omnes::Bus} documentation for the available methods. The only
# difference for the mixing use case is that the methods are directly called in
# the including instance.
#
# ```
# class MyClass
#   include Omnes
#
#   def initialize
#     register(:foo)
#   end
#
#   def call
#     publish(:foo, bar: :baz)
#   end
# end
# ```
#
# Refer to {Omnes::Subscriber} for how to provide event handlers through methods
# defined in a class.
module Omnes
  # Shortcut to access the configuration for different Omnes components
  #
  # @return [Omnes::Config]
  def self.config
    Config
  end

  # Wrapper for the configuration of Omnes components
  #
  # TODO: Make automation for it
  module Config
    # {Omnes::Subscriber} configuration
    #
    # @return [Dry::Configurable::Config]
    def self.subscriber
      Omnes::Subscriber.config.tap do |klass|
        klass.define_singleton_method(:adapter) do
          Module.new do
            def self.sidekiq
              Omnes::Subscriber::Adapter::Sidekiq.config
            end
          end
        end
      end
    end

    # {Omnes::Event} configuration
    #
    # @return [Dry::Configurable::Config]
    def self.event
      Omnes::Event.config
    end
  end

  # @api private
  def self.included(klass)
    bus = Bus.new(cal_loc_start: 2)
    klass.define_method(:omnes_bus) { bus }
    Bus.instance_methods(false).each do |method|
      klass.define_method(method) do |*args, **kwargs, &block|
        omnes_bus.send(method, *args, **kwargs, &block)
      end
    end
  end
end
