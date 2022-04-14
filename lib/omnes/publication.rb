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

    # Publication context, shared by all triggered executions
    #
    # @return [Omnes::PublicationContext]
    attr_reader :context

    # @api private
    def initialize(event:, executions:, context:)
      @event = event
      @executions = executions
      @context = context
    end
  end
end
