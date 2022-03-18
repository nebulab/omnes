# frozen_string_literal: true

require "omnes/errors"

module Omnes
  # Registry of known event names
  #
  # Before publishing or subscribing to an event, its name must be registered to
  # the instance associated with the bus (see {Omnes::Bus#register}).
  class Registry
    # Wraps the registration of an event
    class Registration
      # @!attribute [r] event_name
      #   @return [Symbol]
      attr_reader :event_name

      # @!attribute [r] caller_location
      #   @return [Thread::Backtrace::Location]
      attr_reader :caller_location

      def initialize(event_name:, caller_location:)
        @event_name = event_name
        @caller_location = caller_location
      end
    end

    # @!attribute [r] registrations
    #   @return [Array<Omnes::Registry::Registration>]
    attr_reader :registrations

    def initialize(registrations: [])
      @registrations = registrations
    end

    # @api private
    def register(event_name, caller_location: caller_locations(1)[0])
      raise InvalidEventNameError.new(event_name: event_name) unless valid_event_name?(event_name)

      registration = registration(event_name)
      raise AlreadyRegisteredEventError.new(event_name: event_name, registration: registration) if registration

      Registration.new(event_name: event_name, caller_location: caller_location).tap do |reg|
        @registrations << reg
      end
    end

    # Removes an event name from the registry
    #
    # @param event_name [Symbol]
    def unregister(event_name)
      check_event_name(event_name)

      @registrations.delete_if { |regs| regs.event_name == event_name }
    end

    # Returns an array with all registered event names
    #
    # @return [Array<Symbol>]
    def event_names
      registrations.map(&:event_name)
    end

    # Returns the registration, if present, for the event name
    #
    # @param event_name [Symbol]
    #
    # @return [Omnes::Registry::Registration, nil]
    def registration(event_name)
      registrations.find { |reg| reg.event_name == event_name }
    end

    # Returns whether a given event name is registered
    #
    # Use {#check_event_name} for a raising version of it.
    #
    # @param event_name [Symbol]
    #
    # @return [Boolean]
    def registered?(event_name)
      !registration(event_name).nil?
    end

    # Checks whether given event name is present in the registry
    #
    # Use {#registered?} for a predicate version of it.
    #
    # @param event_name [Symbol]
    #
    # @raise [UnknownEventError] if the event is not registered
    def check_event_name(event_name)
      return if registered?(event_name)

      raise UnknownEventError.new(event_name: event_name, known_events: event_names)
    end

    private

    def valid_event_name?(event_name)
      event_name.is_a?(Symbol)
    end
  end
end
