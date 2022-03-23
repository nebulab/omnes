# frozen_string_literal: true

module Omnes
  # The result of publishing an event
  #
  # It encapsulates a published {Omnes::Event} as well as the
  # {Omnes::Execution}s it originated.
  #
  # This class is useful mainly for debugging and logging purposes. An
  # instance of it is returned on {Omnes::Bus#publish}.
  class Publication
    # Published event
    #
    # @return [#name]
    attr_reader :event

    # Subscription executions that the publication originated
    #
    # @return [Array<Omnes::Execution>]
    attr_reader :executions

    # Location for the event caller
    #
    # It's usually set by {Omnes::Bus#publish}, and it points to the caller of
    # that method.
    #
    # @return [Thread::Backtrace::Location]
    attr_reader :caller_location

    # Time of the event publication
    #
    # @return [Time]
    attr_reader :time

    # @api private
    def initialize(event:, executions:, caller_location:, time:)
      @event = event
      @executions = executions
      @caller_location = caller_location
      @time = time
    end
  end
end
