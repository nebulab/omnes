# frozen_string_literal: true

module Omnes
  # The result of firing an event
  #
  # It encapsulates a published {Omnes::Event} as well as the
  # {Omnes::Execution}s it originated.
  #
  # This class is useful mainly for debugging and logging purposes. An
  # instance of it is returned on {Omnes::Bus#publish}.
  class Firing
    # Fired event
    #
    # @return [Omnes::Event]
    attr_reader :event

    # Subscriber executions that the firing originated
    #
    # @return [Array<Omnes::Execution>]
    attr_reader :executions

    # @api private
    def initialize(event:, executions:)
      @event = event
      @executions = executions
    end
  end
end
