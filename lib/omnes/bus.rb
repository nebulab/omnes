# frozen_string_literal: true

require "omnes/registry"
require "omnes/subscription"
require "omnes/publication"
require "omnes/unstructured_event"

module Omnes
  # An Event Bus for pub/sub architectures
  #
  # An instance of this class works as an Event Bus middleware for publishers of
  # events and their subscriptions.
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
  # Otherwise, you can use an event instance:
  #
  # @example
  #   class Foo < Omnes::Event
  #     attr_reader :bar
  #
  #     def initialize
  #       @bar = true
  #     end
  #   end
  #
  #   bus.publish(Foo.new)
  #
  #
  # Lastly, you use {#subscribe} to add a subscription to the event.
  #
  # @example
  #   bus.subscribe(:foo) do |event|
  #     do_something if event.payload[:bar]
  #   end
  class Bus
    # @api private
    attr_reader :subscriptions, :registry, :caller_location_start

    # @api private
    def self.EventType(value, **payload)
      case value
      when Symbol
        UnstructuredEvent.new(name: value, payload: payload)
      else
        value
      end
    end

    def initialize(subscriptions: [], registry: Registry.new, caller_location_start: 1)
      @subscriptions = subscriptions
      @registry = registry
      @caller_location_start = caller_location_start
    end

    # Registers an event
    #
    # This step is needed before publishing, subscribing or unsubscribing an
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
    # @raise [Omnes::AlreadyRegisteredEventError] when the event is already
    # registered
    # @raise [Omnes::InvalidEventNameError] when the event is not a {Symbol}
    #
    # @return [Omnes::Registry::Registration]
    def register(event_name, caller_location: caller_locations(caller_location_start)[0])
      registry.register(event_name, caller_location: caller_location)
    end

    # Publishes an event, running all its subscriptions
    #
    # @overload publish(event_name, caller_location:, **payload)
    #   Publishes an {Omnes::UnstructuredEvent} instance.
    #   @param event_name [Symbol] Name of the event
    #   @param caller_location [Thread::Backtrace::Location] Caller location
    #   associated to the publication. Useful for debugging (shown in error
    #   messages). It defaults to this method's caller.
    #   @param **payload [Hash] Payload published with the event, meant to be
    #   consumed by subscriptions
    #
    #   @example
    #     bus = Omnes::Bus.new
    #     bus.register(:foo)
    #     bus.publish(:foo, bar: true)
    #
    #     @return [Omnes::Publication] A publication object encapsulating metadata for
    #     the event and the originated subscription executions
    #
    # @overload publish(event, caller_location:)
    #   Publishes an event instance.
    #   @param event [#name] The event instance
    #
    #   @return [Omnes::Publication] A publication object encapsulating metadata for
    #   the event and the originated subscription executions
    #
    #   @example
    #     bus = Omnes::Bus.new
    #     class Foo < Omnes::Event
    #       attr_reader :bar
    #
    #       def initialize
    #         @bar = true
    #       end
    #     end
    #     bus.register(:foo)
    #     bus.publish(Foo.new)
    def publish(event,
                caller_location: caller_locations(caller_location_start)[0], **payload)
      event = self.class.EventType(event, **payload)
      registry.check_event_name(event.name)
      executions = subscriptions_for_event(event).map do |subscription|
        subscription.(event)
      end
      Publication.new(
        event: event,
        executions: executions,
        caller_location: caller_location,
        publication_time: Time.now.utc
      )
    end

    def subscribe_with_matcher(matcher, callable = nil, &block)
      callback = callable || block
      Subscription.new(matcher: matcher, callback: callback).tap do |subscription|
        @subscriptions << subscription
      end
    end

    # Subscribe a subscription to one or more events
    #
    # The provided callable object or block is executed every time a matching
    # event is published.
    #
    # @param event_name [Symbol] The name of the event
    # @param callable [#call] Code to execute when a matching is triggered. It
    # takes the published event.
    # @yield Alternative way to provide the code to execute
    #
    # @return [Omnes::Bus#Subscription] A subscription object that can be used as
    # reference in order to remove the subscription.
    #
    # @example
    #   bus = Omnes::Bus.new
    #   bus.register(:foo)
    #   bus.subscribe(:foo) do |event|
    #     do_something if event.payload[:foo]
    #   end
    def subscribe(event_name, callable = nil, &block)
      registry.check_event_name(event_name)
      subscribe_with_matcher(Subscription::SINGLE_EVENT_MATCHER.curry[event_name], callable, &block)
    end

    def subscribe_to_all(callable = nil, &block)
      subscribe_with_matcher(Subscription::ALL_EVENTS_MATCHER, callable, &block)
    end

    # Removes a subscription
    #
    # The subscribed is removed from the queue.
    #
    # @param subscription [Omnes::Subscription]
    def unsubscribe(subscription)
      @subscriptions.delete(subscription)
    end

    # Returns new bus with same registry and only specified subscriptions
    #
    # That's something useful for testing purposes, as it allows to silence
    # subscriptions that are not part of the system under test.
    #
    # @param subscriptions [Array<Omnes::Subscription>]
    def with_subscriptions(subscriptions)
      self.class.new(subscriptions: subscriptions, registry: registry)
    end

    private

    def subscriptions_for_event(event_name)
      @subscriptions.select do |subscription|
        subscription.matches?(event_name)
      end
    end
  end
end
