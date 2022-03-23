# frozen_string_literal: true

module Omnes
  # Event with a payload defined at publication time
  #
  # An instance of it is automatically created on {Omnes::Bus#publish} when a
  # name and payload are given.
  #
  # @example
  #   bus = Omnes::Bus.new
  #   bus.register(:foo)
  #   bus.subscribe(:foo) do |event|
  #     puts event[:bar]
  #   end
  #   bus.publish(:foo, bar: 'bar') # it'll generate an instance of this class
  class UnstructuredEvent
    # Name of the event
    #
    # @return [Symbol]
    attr_reader :omnes_event_name

    # Information made available to the matching subscriptions
    #
    # @return [Hash]
    attr_reader :payload

    # @api private
    def initialize(payload:, omnes_event_name:)
      @payload = payload
      @omnes_event_name = omnes_event_name
    end

    # Delegates to {#payload}
    #
    # @param key [Any]
    #
    # @return Any
    def [](key)
      payload[key]
    end
  end
end
