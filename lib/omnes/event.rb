# frozen_string_literal: true

require "dry/configurable"

module Omnes
  # Abstract class for events
  #
  # Any instance of a class inheriting from this one can be used as an event on
  # {Omnes::Bus#publish}. It's yielded to all matching subscriptions (see
  # {Omnes::Bus#subscribe}.
  #
  # @example
  #   class MyEvent < Omnes::Event
  #     attr_reader :event
  #
  #     def initialize(id:)
  #       @id = id
  #     end
  #   end
  #
  #   bus = Omnes::Bus.new
  #   bus.register(:my_event)
  #   bus.subscribe(:my_event) do |event|
  #     puts event.id
  #   end
  #   bus.publish(MyEvent.new(1))
  #
  # It can be accessed through the returned value in {Omnes::Bus#publish}.
  #
  # Custom classes an also be used as events. The only requirements is that
  # they respond to a `#name` method, as this one does.
  class Event
    extend Dry::Configurable

    # Default name builer for event classes.
    #
    # It returns the underscored class name. E.g:
    #
    # Foo -> :foo
    # FooBar -> :foo_bar
    # FBar -> :f_bar
    # Foo::Bar -> :foo_bar
    #
    # You can change it with `Omnes::Event.config.name_builder =
    # my_name_builder`.
    #
    # @return [Symbol]
    DEFAULT_NAME_BUILDER = lambda do |instance|
      instance.class.name
              .gsub(/([[:alpha:]])([[:upper:]])/, '\1_\2')
              .gsub("::", "_")
              .downcase
              .to_sym
    end

    setting :name_builder, default: DEFAULT_NAME_BUILDER

    # Event name
    #
    # Use it to register or subscribe to the event.
    #
    def name
      self.class.config.name_builder.(self)
    end
  end
end
