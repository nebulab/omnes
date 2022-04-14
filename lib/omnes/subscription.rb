# frozen_string_literal: true

require "benchmark"
require "omnes/execution"
require "securerandom"

module Omnes
  # Subscription to an event
  #
  # An instance of it is returned on {Omnes::Bus} subscription methods.
  #
  # Usually, it isn't used directly beyond as a reference to unsubscribe.
  #
  # ```
  # bus = Omnes::Bus.new
  # bus.register(:foo)
  # subscription = bus.subscribe(:foo) { |_event| do_something }
  # bus.unsubscribe(subscription)
  # ```
  class Subscription
    SINGLE_EVENT_MATCHER = lambda do |subscribed, candidate|
      subscribed == candidate.omnes_event_name
    end

    ALL_EVENTS_MATCHER = ->(_candidate) { true }

    # @api private
    def self.random_id
      SecureRandom.uuid.to_sym
    end

    # @api private
    def self.takes_publication_context?(callable)
      callable.parameters.count == 2
    end

    # @api private
    attr_reader :matcher, :callback, :id

    # @api private
    def initialize(matcher:, callback:, id:)
      raise Omnes::InvalidSubscriptionNameError.new(id: id) unless id.is_a?(Symbol)

      @matcher = matcher
      @callback = callback
      @id = id
    end

    # @api private
    def call(event, publication_context)
      result = nil
      benchmark = Benchmark.measure do
        # work around Ruby not being able to tell remaining arity for a curried
        # function (or uncurrying), because we want to be able to create subscriber
        # adapters partially applying the subscriber instance
        result = begin
          @callback.(event, publication_context)
        rescue ArgumentError
          @callback.(event)
        end
      end

      Execution.new(subscription: self, result: result, benchmark: benchmark)
    end

    # @api private
    def matches?(candidate)
      matcher.(candidate)
    end

    # Returns self within a single-item array
    #
    # This method can be helpful to act polymorphic to an array of subscriptions
    # from an {Omnes::Subscriber}, usually for testing purposes.
    def subscriptions
      [self]
    end
  end
end
