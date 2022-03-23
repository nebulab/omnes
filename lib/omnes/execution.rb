# frozen_string_literal: true

module Omnes
  # Execution of an {Omnes::Subscription}
  #
  # When an event is published, it executes all matching subscriptions. Every
  # single execution is represented as an instance of this class. It contains
  # the result value of the subscriptions along with helpful metadata as the
  # time of the execution or a benchmark for it.
  #
  # You'll most likely interact with this class for debugging or logging
  # purposes through a {Omnes::Publication} returned on {Omnes::Bus#publish}.
  class Execution
    # The subscription to which the execution belongs
    #
    # @return [Omnes::Subscription]
    attr_reader :subscription

    # The value returned by the {#subscription}'s callback
    #
    # @return [Any]
    attr_reader :result

    # Benchmark for the {#subscription}'s callback
    #
    # @return [Benchmark::Tms]
    attr_reader :benchmark

    # Time of execution
    #
    # @return [Time]
    attr_reader :time

    # @private
    def initialize(subscription:, result:, benchmark:, time: Time.now.utc)
      @subscription = subscription
      @result = result
      @benchmark = benchmark
      @time = time
    end
  end
end
