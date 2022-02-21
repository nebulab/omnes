# frozen_string_literal: true

module Omnes
  # Execution of a {Omnes::Subscriber}
  #
  # When an event is published, it executes all subscribed subscribers. Every
  # single execution is represented as an instance of this class. It contains
  # the result value of the subscriber, along with helpful metadata as the time of
  # the execution or a benchmark for it.
  #
  # You'll most likely interact with this class for debugging or logging
  # purposes through the returned value in {Omnes::Bus#publish}.
  class Execution
    # The subscriber to which the execution belongs
    #
    # @return [Omnes::Subscriber]
    attr_reader :subscriber

    # The value returned by the {#subscriber}'s block
    #
    # @return [Any]
    attr_reader :result

    # Benchmark for the {#subscriber}'s block
    #
    # @return [Benchmark::Tms]
    attr_reader :benchmark

    # Time of execution
    #
    # @return [Time]
    attr_reader :execution_time

    # @private
    def initialize(subscriber:, result:, benchmark:, execution_time: Time.now.utc)
      @subscriber = subscriber
      @result = result
      @benchmark = benchmark
      @execution_time = execution_time
    end
  end
end
