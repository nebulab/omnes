# frozen_string_literal: true

require 'omnes/event'
require 'omnes/subscription'
require 'omnes/firing'
require 'omnes/registry'

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
  # Lastly, you use {#subscribe} to add a subscription to the event.
  #
  # @example
  #   bus.subscribe(:foo) do |event|
  #     do_something if event.payload[:bar]
  #   end
  class Bus
    # @api private
    attr_reader :subscriptions, :registry

    def initialize(subscriptions: [], registry: Registry.new)
      @subscriptions = subscriptions
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

    # Publishes an event, running all its subscriptions
    #
    # @param event_name [Symbol] Name of the event
    # @param caller_location [Thread::Backtrace::Location] Caller location
    # associated to the firing. Useful for debugging (shown in error
    # messages). It defaults to this method's caller.
    # @param **payload [Hash] Payload published with the event, meant to be
    # consumed by subscriptions
    #
    # @return [Omnes::Firing] A firing object encapsulating metadata for
    # the event and the originated subscription executions
    #
    # @example
    #   bus = Omnes::Bus.new
    #   bus.register(:foo)
    #   bus.publish(:foo, bar: true)
    def publish(event_name, caller_location: caller_locations(1)[0], **payload)
      event_name = registry.sanitize_event_name(event_name)
      event = Event.new(payload: payload, caller_location: caller_location)
      executions = subscriptions_for_event(event_name).map do |subscription|
        subscription.call(event)
      end
      Firing.new(event: event, executions: executions)
    end

    # Subscribe a subscription to one or more events
    #
    # The provided block is executed every time a matching event is publshed.
    #
    # @param event_name_or_regexp [Symbol, Regexp] The name of the event or,
    # when a {Regexp}, a set of matching events
    # @yield Code to execute when a matching is triggered
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
    def subscribe(event_name_or_regexp, &block)
      event_name_or_regexp = registry.sanitize_event_name(event_name_or_regexp) unless event_name_or_regexp.is_a?(Regexp)
      Subscription.new(pattern: event_name_or_regexp, block: block).tap do |subscription|
        @subscriptions << subscription
      end
    end

    # Removes a subscription
    #
    # The subscribed is removed from the queue.
    #
    # @param subscription [Omnes::Subscription]
    def unsubscribe(subscription)
      @subscriptions.delete(subscription)
    end

    # Unregisters an event
    #
    # Associated subscriptions won't run if the event is re-registered. Direct
    # subscriptions are removed from the queue (see {#unsubscribe}), while regexp
    # subscriptions will exclude given event.
    #
    # @param event_name [Symbol]
    def unregister(event_name)
      event_name = registry.sanitize_event_name(event_name)
      registry.unregister(event_name)
      @subscriptions.each do |subscription|
        next unless subscription.matches?(event_name)

        if subscription.regexp?
          subscription.exclude(event_name)
        else
          unsubscribe(subscription)
        end
      end
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
