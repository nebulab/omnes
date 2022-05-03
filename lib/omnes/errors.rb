# frozen_string_literal: true

module Omnes
  class Error < StandardError; end

  # Raised when an event name is not known
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
        #{suggestions_message if defined?(DidYouMean::PlainFormatter)}

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

  # Raised when trying to register the same event name a second time
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

  # Raised when a subscription is not known by a bus
  class UnknownSubscriptionError < Error
    attr_reader :subscription, :bus

    def initialize(subscription:, bus:)
      @subscription = subscription
      @bus = bus
      super(default_message)
    end

    private

    def default_message
      <<~MSG
        #{subscription.inspect} is not a subscription known by bus
        #{bus.inspect}
      MSG
    end
  end

  # Raised when given subscription id is already in use
  class DuplicateSubscriptionIdError < Error
    attr_reader :id, :bus

    def initialize(id:, bus:)
      @id = id
      @bus = bus
      super(default_message)
    end

    private

    def default_message
      <<~MSG
        #{id} has already been used as a subscription identifier
      MSG
    end
  end

  # Raised when trying to set an invalid subscription identifier
  class InvalidSubscriptionNameError < Error
    attr_reader :id

    def initialize(id:)
      @id = id
      super(default_message)
    end

    private

    def default_message
      <<~MSG
        #{id.inspect} is not a valid subscription identifier. Only symbols are
        #allowed.
      MSG
    end
  end
end
