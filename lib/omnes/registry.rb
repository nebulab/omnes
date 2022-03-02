# frozen_string_literal: true

require "omnes/errors"

module Omnes
  # Registry of known events
  #
  # @api private
  class Registry
    # @api private
    class Registration
      attr_reader :event_name, :caller_location

      def initialize(event_name:, caller_location:)
        @event_name = event_name
        @caller_location = caller_location
      end
    end

    attr_reader :registrations

    def initialize(registrations: [])
      @registrations = registrations
    end

    def register(event_name, caller_location: caller_locations(1)[0])
      raise InvalidEventNameError.new(event_name: event_name) unless event_name.is_a?(Symbol)

      registration = registration(event_name)
      raise AlreadyRegisteredEventError.new(event_name: event_name, registration: registration) if registration

      Registration.new(event_name: event_name, caller_location: caller_location).tap do |reg|
        @registrations << reg
      end
    end

    def unregister(event_name)
      check_event_name(event_name)

      @registrations.delete_if { |regs| regs.event_name == event_name }
    end

    def registration(event_name)
      registrations.find { |reg| reg.event_name == event_name }
    end

    def registered?(event_name)
      !registration(event_name).nil?
    end

    def event_names
      registrations.map(&:event_name)
    end

    def check_event_name(event_name)
      return if registered?(event_name)

      raise UnknownEventError.new(event_name: event_name, known_events: event_names)
    end
  end
end
