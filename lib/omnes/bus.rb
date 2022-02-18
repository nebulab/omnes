# frozen_string_literal: true

require 'omnes/event'
require 'omnes/listener'
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
  #   bus.fire(:foo, bar: true)
  #
  # Lastly, you use {#subscribe} to add a listener to the event.
  #
  # @example
  #   bus.subscribe(:foo) do |event|
  #     do_something if event.payload[:bar]
  #   end
  class Bus
    # @api private
    attr_reader :listeners, :registry

    def initialize(listeners = [], registry = Registry.new)
      @listeners = listeners
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
    # the event and the originated listener executions
    #
    # @example
    #   bus = Omnes::Bus.new
    #   bus.register(:foo)
    #   bus.fire(:foo, bar: true)
    def fire(event_name, caller_location: caller_locations(1)[0], **payload)
      registry.check_event_name_registered(event_name)
      event = Event.new(payload: payload, caller_location: caller_location)
      executions = listeners_for_event(event_name).map do |listener|
        listener.call(event)
      end
      Firing.new(event: event, executions: executions)
    end

    # Subscribe a listener to one or more events
    #
    # The provided block is executed every time a matching event is fired.
    #
    # @param event_name_or_regexp [Symbol, Regexp] The name of the event or,
    # when a {Regexp}, a set of matching events
    # @yield Code to execute when a matching is triggered
    #
    # @return [Omnes::Bus#Listener] A subscription object that can be used as
    # reference in order to remove the subscription.
    #
    # @example
    #   bus = Omnes::Bus.new
    #   bus.register(:foo)
    #   bus.subscribe(:foo) do |event|
    #     do_something if event.payload[:foo]
    #   end
    def subscribe(event_name_or_regexp, &block)
      registry.check_event_name_registered(event_name_or_regexp) if event_name?(event_name_or_regexp)
      Listener.new(pattern: event_name_or_regexp, block: block).tap do |listener|
        @listeners << listener
      end
    end

    # Unsubscribes a listener or all listeners for a given event
    #
    # When unsubscribing from an event, all previous listeners are removed.
    # Still, you can add new subscriptions to the same event and they'll be
    # called if the event is fired:
    #
    # @param listener_or_event_name [Symbol, Omnes::Listener] The event name or
    # the listener object.
    #
    # @example
    #   bus = Omnes::Bus.new
    #   bus.register(:foo)
    #   bus.subscribe(:foo) { do_something }
    #   bus.unsubscribe(:foo)
    #   bus.subscribe(:foo) { do_something_else }
    #   bus.fire(:foo) # `do_something_else` will be called, but
    #   # `do_something` won't
    def unsubscribe(listener_or_event_name)
      if listener_or_event_name.is_a?(Listener)
        unsubscribe_listener(listener_or_event_name)
      else
        registry.check_event_name_registered(listener_or_event_name) if event_name?(listener_or_event_name)
        unsubscribe_event(listener_or_event_name)
      end
    end

    # Returns new bus with same registry and only specified listeners
    #
    # That's something useful for testing purposes, as it allows to silence
    # listeners that are not part of the system under test.
    #
    # @param listeners [Array<Omnes::Listener>]
    def with_listeners(listeners)
      self.class.new(listeners, registry)
    end

    private

    def listeners_for_event(event_name)
      @listeners.select do |listener|
        listener.matches?(event_name)
      end
    end

    def unsubscribe_listener(listener)
      @listeners.delete(listener)
    end

    def unsubscribe_event(event_name)
      @listeners.each do |listener|
        listener.unsubscribe(event_name)
      end
    end

    def event_name?(candidate)
      candidate.is_a?(Symbol)
    end
  end
end
