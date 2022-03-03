# frozen_string_literal: true

require "benchmark"
require "omnes/execution"

module Omnes
  # Subscription to an event
  #
  # An instance of it is returned on {Omnes::Bus#subscribe}.
  #
  # You're not expected to perform any action with it, besides using it as
  # a reference to unsubscribe.
  #
  # @example
  #   bus = Omnes::Bus.new
  #   bus.register(:foo)
  #   subscription = bus.subscribe(:foo) { do_something }
  #   bus.unsubscribe subscription
  class Subscription
    # @api private
    attr_reader :event_name, :callback

    # @api private
    def initialize(event_name:, callback:)
      @event_name = event_name
      @callback = callback
    end

    # @api private
    def call(event)
      result = nil
      benchmark = Benchmark.measure do
        result = @callback.call(event)
      end

      Execution.new(subscription: self, result: result, benchmark: benchmark)
    end

    # @api private
    def matches?(candidate)
      event_name == candidate
    end

    # @api private
    def subscriptions
      [self]
    end
  end
end
