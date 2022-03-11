# frozen_string_literal: true

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
  # Custom classed can also be used as events. The only requirements is that
  # they respond to a `#name` method, as this one does.
  class Event
    # Event name
    #
    # Use it to register or subscribe to tre event.
    #
    # It returns the underscored class name. E.g:
    #
    # Foo -> :foo
    # FooBar -> :foo_bar
    # FBar -> :f_bar
    # Foo::Bar -> :foo_bar
    #
    # @return [Symbol]
    def name
      self.class.name
          .gsub(/([[:alpha:]])([[:upper:]])/, '\1_\2')
          .gsub("::", "_")
          .downcase
          .to_sym
    end
  end
end
