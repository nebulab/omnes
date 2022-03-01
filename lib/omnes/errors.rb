# frozen_string_literal: true

module Omnes
  class Error < StandardError; end

  # Raised when event is not known
  class UnknownEventError < Error
    attr_reader :event_name, :known_events

    def initialize(event_name:, known_events:)
      @event_name = event_name
      @known_events = known_events
      super(default_message)
    end

    private

    def default_message
      <<~MSG
        '#{event_name}' event is not registered.
        #{suggestions_message}

        All known events are:

          '#{known_events.join("', '")}'
      MSG
    end

    def suggestions_message
      DidYouMean::PlainFormatter.new.message_for(suggestions)
    end

    def suggestions
      dictionary = DidYouMean::SpellChecker.new(dictionary: known_events)

      dictionary.correct(event_name)
    end
  end

  # Raised when trying to register an invalid event name
  class InvalidEventNameError < Error
    attr_reader :event_name

    def initialize(event_name:)
      @event_name = event_name
      super(default_message)
    end

    private

    def default_message
      <<~MSG
        #{event_name.inspect} is not a valid event name. Only symbols can be
        registered.
      MSG
    end
  end

  # Raised when trying to register an event a second time
  class AlreadyRegisteredEventError < Error
    attr_reader :event_name, :registration

    def initialize(event_name:, registration:)
      @event_name = event_name
      @registration = registration
      super(default_message)
    end

    private

    def default_message
      <<~MSG
        Can't register #{event_name} event as it's already registered.

        The registration happened at:

        #{registration.caller_location}
      MSG
    end
  end
end
