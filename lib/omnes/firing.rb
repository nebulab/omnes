# frozen_string_literal: true

module Omnes
  # The result of firing an event
  #
  # It encapsulates a fired {Spree::Event::Event} as well as the
  # {Spree::Event::Execution}s it originated.
  #
  # This class is useful mainly for debugging and logging purposes. An
  # instance of it is returned on {Spree::Event.fire}.
  class Firing
    # Fired event
    #
    # @return [Spree::Event::Event]
    attr_reader :event

    # Listener executions that the firing originated
    #
    # @return [Array<Spree::Event::Execution>]
    attr_reader :executions

    # @api private
    def initialize(event:, executions:)
      @event = event
      @executions = executions
    end
  end
end
