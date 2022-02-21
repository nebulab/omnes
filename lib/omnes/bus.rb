# frozen_string_literal: true

require 'omnes/event'
require 'omnes/subscriber'
require 'omnes/firing'
require 'omnes/registry'

module Omnes
  # An Event Bus for pub/sub architectures
  #
  # An instance of this class works as an Event Bus middleware for publishers of
  # events and their subscribers.
  #
  # The same behavior can be incorporated into any class that includes the
  # {Omnes} module. See there for more details.
  #
  # Before working with a given event, it needs to be registered in the bus.
  #
  # @example
  #   bus = Omnes::Bus.new
  #   bus.register(:foo)
  #
  # You can then publish it alongside a payload:
  #
  # @example
  #   bus.publish(:foo, bar: true)
  #
  # Lastly, you use {#subscribe} to add a subscriber to the event.
  #
  # @example
  #   bus.subscribe(:foo) do |event|
  #     do_something if event.payload[:bar]
  #   end
  class Bus
    # @api private
    attr_reader :subscribers, :registry

    def initialize(subscribers: [], registry: Registry.new)
      @subscribers = subscribers
      @registry = registry
    end

    # Registers an event
    #
    # This step is needed before firing, subscribing or unsubscribing an
    # event. It helps to prevent typos and naming collision.
    #
    # @example
    #   bus = Omnes::Bus.new
    #   bus.register(:foo)
    #
    # @param event_name [Symbol]
    # @param caller_location [Thread::Backtrace::Location] Caller location
    # associated to the registration. Useful for debugging (shown in error
    # messages). It defaults to this method's caller.
    #
    # @return [Omnes::Registry::Registration]
    def register(event_name, caller_location: caller_locations(1)[0])
      registry.register(event_name, caller_location: caller_location)
    end

    # Publishes an event, running all its subscribers
    #
    # @param event_name [Symbol] Name of the event
    # @param caller_location [Thread::Backtrace::Location] Caller location
    # associated to the firing. Useful for debugging (shown in error
    # messages). It defaults to this method's caller.
    # @param **payload [Hash] Payload published with the event, meant to be
    # consumed by subscribers
    #
    # @return [Omnes::Firing] A firing object encapsulating metadata for
    # the event and the originated subscriber executions
    #
    # @example
    #   bus = Omnes::Bus.new
    #   bus.register(:foo)
    #   bus.publish(:foo, bar: true)
    def publish(event_name, caller_location: caller_locations(1)[0], **payload)
      event_name = registry.sanitize_event_name(event_name)
      event = Event.new(payload: payload, caller_location: caller_location)
      executions = subscribers_for_event(event_name).map do |subscriber|
        subscriber.call(event)
      end
      Firing.new(event: event, executions: executions)
    end

    # Subscribe a subscriber to one or more events
    #
    # The provided block is executed every time a matching event is publshed.
    #
    # @param event_name_or_regexp [Symbol, Regexp] The name of the event or,
    # when a {Regexp}, a set of matching events
    # @yield Code to execute when a matching is triggered
    #
    # @return [Omnes::Bus#Subscriber] A subscription object that can be used as
    # reference in order to remove the subscription.
    #
    # @example
    #   bus = Omnes::Bus.new
    #   bus.register(:foo)
    #   bus.subscribe(:foo) do |event|
    #     do_something if event.payload[:foo]
    #   end
    def subscribe(event_name_or_regexp, &block)
      event_name_or_regexp = registry.sanitize_event_name(event_name_or_regexp) unless event_name_or_regexp.is_a?(Regexp)
      Subscriber.new(pattern: event_name_or_regexp, block: block).tap do |subscriber|
        @subscribers << subscriber
      end
    end

    # Unsubscribes a subscriber or all subscribers for a given event
    #
    # When unsubscribing from an event, all previous subscribers are removed.
    # Still, you can add new subscriptions to the same event and they'll be
    # called if the event is published:
    #
    # @param subscriber_or_event_name [Symbol, Omnes::Subscriber] The event name or
    # the subscriber object.
    #
    # @example
    #   bus = Omnes::Bus.new
    #   bus.register(:foo)
    #   bus.subscribe(:foo) { do_something }
    #   bus.unsubscribe(:foo)
    #   bus.subscribe(:foo) { do_something_else }
    #   bus.publish(:foo) # `do_something_else` will be called, but
    #   # `do_something` won't
    def unsubscribe(subscriber_or_event_name)
      if subscriber_or_event_name.is_a?(Subscriber)
        unsubscribe_subscriber(subscriber_or_event_name)
      else
        event_name = registry.sanitize_event_name(subscriber_or_event_name)
        unsubscribe_event(event_name)
      end
    end

    # Returns new bus with same registry and only specified subscribers
    #
    # That's something useful for testing purposes, as it allows to silence
    # subscribers that are not part of the system under test.
    #
    # @param subscribers [Array<Omnes::Subscriber>]
    def with_subscribers(subscribers)
      self.class.new(subscribers: subscribers, registry: registry)
    end

    private

    def subscribers_for_event(event_name)
      @subscribers.select do |subscriber|
        subscriber.matches?(event_name)
      end
    end

    def unsubscribe_subscriber(subscriber)
      @subscribers.delete(subscriber)
    end

    def unsubscribe_event(event_name)
      @subscribers.each do |subscriber|
        next unless subscriber.matches?(event_name)

        if subscriber.regexp?
          subscriber.exclude(event_name)
        else
          unsubscribe_subscriber(subscriber)
        end
      end
    end
  end
end
