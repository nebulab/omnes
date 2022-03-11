# frozen_string_literal: true

module Omnes
  # Event with a payload defined at publication time
  #
  # An instance of it is automatically created on {Omnes::Bus#publish} when a
  # name and payload are given. That's what is yielded to all matching
  # subscriptions (see {Omnes::Bus#subscribe}.
  #
  # @example
  #   bus = Omnes::Bus.new
  #   bus.register(:foo)
  #   bus.subscribe(:foo) do |event|
  #     puts event[:bar]
  #   end
  #   bus.publish(:foo, bar: 'bar')
  #
  # As any other event, it can be accessed through the returned value in
  # {Omnes::Bus#publish}.
  class UnstructuredEvent
    # Name of the event
    #
    # @return [Symbol]
    attr_reader :name

    # Information made available to the matching subscriptions
    #
    # @return [Hash]
    attr_reader :payload

    # @api private
    def initialize(payload:, name:, **kwargs)
      @payload = payload
      @name = name
      super(**kwargs)
    end

    # Delegates to {#payload}
    #
    # @param key [Symbol]
    #
    # @return Any
    def [](key)
      payload[key]
    end
  end
end
