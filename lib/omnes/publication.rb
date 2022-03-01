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
    # Fired event
    #
    # @return [Omnes::Event]
    attr_reader :event

    # Subscription executions that the publication originated
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
