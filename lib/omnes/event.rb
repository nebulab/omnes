# frozen_string_literal: true

require "dry/configurable"

module Omnes
  # Abstract class for events
  #
  # Any instance of a class inheriting from this one can be used as a published
  # event (see {Omnes::Bus#publish}).
  #
  # ```
  # class MyEvent < Omnes::Event
  #   attr_reader :event
  #
  #   def initialize(id:)
  #     @id = id
  #   end
  # end
  #
  # bus = Omnes::Bus.new
  # bus.register(:my_event)
  # bus.subscribe(:my_event) do |event|
  #   puts event.id
  # end
  # bus.publish(MyEvent.new(1))
  # ```
  class Event
    extend Dry::Configurable

    # Generates the event name for an event instance
    #
    # It returns the underscored class name, with an `Event` suffix removed if
    # present. E.g:
    #
    # - Foo -> `:foo`
    # - FooEvent -> `:foo`
    # - FooBar -> `:foo_bar`
    # - FBar -> `:f_bar`
    # - Foo::Bar -> `:foo_bar`
    #
    # You can also use your custom name builder. It needs to be something
    # callable taking the instance as argument and returning a {Symbol}:
    #
    # ```
    # my_name_builder = ->(instance) { instance.class.name.to_sym }
    # Omnes.config.event.name_builder = my_name_builder
    # ```
    #
    # @return [Symbol]
    DEFAULT_NAME_BUILDER = lambda do |instance|
      instance.class.name
              .chomp("Event")
              .gsub(/([[:alpha:]])([[:upper:]])/, '\1_\2')
              .gsub("::", "_")
              .downcase
              .to_sym
    end

    setting :name_builder, default: DEFAULT_NAME_BUILDER

    # Event name
    #
    # @return [Symbol]
    #
    # @see DEFAULT_NAME_BUILDER
    def name
      self.class.config.name_builder.(self)
    end
  end
end
