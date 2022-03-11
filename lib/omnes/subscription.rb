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
    SINGLE_EVENT_MATCHER = lambda do |subscribed, candidate|
      subscribed == candidate.name
    end

    ALL_EVENTS_MATCHER = ->(_candidate) { true }

    # @api private
    attr_reader :matcher, :callback

    # @api private
    def initialize(matcher:, callback:)
      @matcher = matcher
      @callback = callback
    end

    # @api private
    def call(event)
      result = nil
      benchmark = Benchmark.measure do
        result = @callback.(event)
      end

      Execution.new(subscription: self, result: result, benchmark: benchmark)
    end

    # @api private
    def matches?(candidate)
      matcher.(candidate)
    end

    # @api private
    def subscriptions
      [self]
    end
  end
end
