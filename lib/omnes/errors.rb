# frozen_string_literal: true

module Omnes
  class Error < StandardError; end

  class EventNotKnownError < Error
    attr_reader :event_name

    def initialize(event_name:)
      @event_name = event_name
    end
  end

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
end
