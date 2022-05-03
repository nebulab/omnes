# frozen_string_literal: true

require "omnes/bus"
require "omnes/configurable"
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
  extend Configurable

  nest_config Subscriber
  nest_config Event

  # @api private
  def self.included(klass)
    klass.define_method(:omnes_bus) { @omnes_bus ||= Bus.new(cal_loc_start: 2) }
    Bus.instance_methods(false).each do |method|
      klass.define_method(method) do |*args, **kwargs, &block|
        # TODO: Forward with ... once we deprecate ruby 2.5 & 2.6
        if kwargs.any?
          omnes_bus.send(method, *args, **kwargs, &block)
        else
          omnes_bus.send(method, *args, &block)
        end
      end
    end
  end
end
