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
    SINGLE_EVENT_STRATEGY = lambda do |published, candidate|
      published == candidate
    end

    ALL_EVENTS_STRATEGY = ->(_candidate) { true }

    # @api private
    attr_reader :strategy, :callback

    # @api private
    def initialize(strategy:, callback:)
      @strategy = strategy
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
      strategy.(candidate)
    end

    # @api private
    def subscriptions
      [self]
    end
  end
end
