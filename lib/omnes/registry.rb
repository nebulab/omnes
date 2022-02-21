# frozen_string_literal: true

require 'omnes/errors'

module Omnes
  # Registry of known events
  #
  # @api private
  class Registry
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
      event_name = normalize_event_name(event_name)
      registration = registration(event_name)
      if registration
        raise <<~MSG
            Can't register #{event_name} event as it's already registered.

            The registration happened at:

            #{registration.caller_location}
        MSG
      else
        Registration.new(event_name: event_name, caller_location: caller_location).tap do |reg|
          @registrations << reg
        end
      end
    end

    def unregister(event_name)
      event_name = normalize_event_name(event_name)
      raise <<~MSG unless registered?(event_name)
          #{event_name} is not registered.

          Known events are:

            '#{event_names.join("' '")}'
      MSG

      @registrations.delete_if { |regs| regs.event_name == event_name }
    end

    def registration(event_name)
      event_name = normalize_event_name(event_name)
      registrations.find { |reg| reg.event_name == event_name }
    end

    def registered?(event_name)
      event_name = normalize_event_name(event_name)
      !registration(event_name).nil?
    end

    def event_names
      registrations.map(&:event_name)
    end

    def sanitize_event_name(event_name)
      event_name = normalize_event_name(event_name)
      return event_name if registered?(event_name)

      raise EventNotKnownError.new(event_name: event_name), <<~MSG
        '#{event_name}' is not registered as a valid event name.
        #{suggestions_message(event_name)}

        All known events are:

          '#{event_names.join("', '")}'
      MSG
    end

    private

    def normalize_event_name(event_name)
      event_name.to_sym
    end

    def suggestions(event_name)
      dictionary = DidYouMean::SpellChecker.new(dictionary: event_names)

      dictionary.correct(event_name)
    end

    def suggestions_message(event_name)
      DidYouMean::PlainFormatter.new.message_for(suggestions(event_name))
    end
  end
end
