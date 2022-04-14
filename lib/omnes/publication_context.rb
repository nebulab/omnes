# frozen_string_literal: true

module Omnes
  # Context for an event publication
  #
  # An instance of this class is shared between all the executions that are
  # triggered by the publication of a given event. It's provided to the
  # subscriptions as their second argument when they take it.
  #
  # This class is useful mainly for debugging and logging purposes.
  class PublicationContext
    # Location for the event publisher
    #
    # It's set by {Omnes::Bus#publish}, and it points to the caller of that
    # method.
    #
    # @return [Thread::Backtrace::Location]
    attr_reader :caller_location

    # Time of the event publication
    #
    # @return [Time]
    attr_reader :time

    # @api private
    def initialize(caller_location:, time:)
      @caller_location = caller_location
      @time = time
    end

    # Serialized version of a publication context
    #
    # @return Hash<String, String>
    def serialized
      {
        "caller_location" => caller_location.to_s,
        "time" => time.to_s
      }
    end
  end
end
