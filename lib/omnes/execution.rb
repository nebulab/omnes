# frozen_string_literal: true

module Omnes
  # Execution of a {Omnes::Listener}
  #
  # When an event is published, it executes all subscribed listeners. Every
  # single execution is represented as an instance of this class. It contains
  # the result value of the listener, along with helpful metadata as the time of
  # the execution or a benchmark for it.
  #
  # You'll most likely interact with this class for debugging or logging
  # purposes through the returned value in {Omnes::Bus#publish}.
  class Execution
    # The listener to which the execution belongs
    #
    # @return [Omnes::Listener]
    attr_reader :listener

    # The value returned by the {#listener}'s block
    #
    # @return [Any]
    attr_reader :result

    # Benchmark for the {#listener}'s block
    #
    # @return [Benchmark::Tms]
    attr_reader :benchmark

    # Time of execution
    #
    # @return [Time]
    attr_reader :execution_time

    # @private
    def initialize(listener:, result:, benchmark:, execution_time: Time.now.utc)
      @listener = listener
      @result = result
      @benchmark = benchmark
      @execution_time = execution_time
    end
  end
end
