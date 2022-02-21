# frozen_string_literal: true

require 'benchmark'
require 'omnes/execution'

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
  #   subscriber = bus.subscribe(:foo) { do_something }
  #   bus.unsubscribe subscriber
  class Subscriber
    # @api private
    attr_reader :pattern, :block

    # @api private
    def initialize(pattern:, block:)
      @pattern = pattern
      @block = block
      @exclusions = []
    end

    # @api private
    def call(event)
      result = nil
      benchmark = Benchmark.measure do
        result = @block.call(event)
      end

      Execution.new(subscriber: self, result: result, benchmark: benchmark)
    end

    # @api private
    def matches?(event_name)
      pattern === event_name &&
        !excludes?(event_name)
    end

    # @api private
    def exclude(event_name)
      @exclusions << event_name
    end

    # @api private
    def subscribers
      [self]
    end

    # @api private
    def regexp?
      pattern.is_a?(Regexp)
    end

    private

    def excludes?(event_name)
      @exclusions.include?(event_name)
    end
  end
end
