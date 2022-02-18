# frozen_string_literal: true

module Omnes
  # A triggered event
  #
  # An instance of it is automatically created on {Omnes::Bus#fire} and yielded
  # to all subscribers (see {Omnes::Bus#subscribe}.
  #
  # @example
  #   bus = Omnes::Bus.new
  #   bus.register(:foo)
  #   bus.subscribe(:foo) do |event|
  #     puts event.payload[:bar]
  #   end
  #   bus.fire :foo, bar: 'bar'
  #
  # Besides, it can be accessed through the returned value in {Omnes::Bus#fire}.
  # It can be useful for debugging and logging purposes, as it contains
  # helpful metadata like the event time or the caller location.
  class Event
    # Hash with the options given to {Omnes::Bus#fire}
    #
    # @return [Hash]
    attr_reader :payload

    # Time of the event firing
    #
    # @return [Time]
    attr_reader :firing_time

    # Location for the event caller
    #
    # It's usually set by {Omnes::Bus#fire}, and it points to the caller of
    # that method.
    #
    # @return [Thread::Backtrace::Location]
    attr_reader :caller_location

    # @api private
    def initialize(payload:, caller_location:, firing_time: Time.now.utc)
      @payload = payload
      @caller_location = caller_location
      @firing_time = firing_time
    end
  end
end
