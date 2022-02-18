# frozen_string_literal: true

module Omnes
  class Error < StandardError; end

  class EventNotKnownError < Error
    attr_reader :event_name

    def initialize(event_name:)
      @event_name = event_name
    end
  end
end
