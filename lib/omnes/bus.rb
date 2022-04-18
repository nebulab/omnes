# frozen_string_literal: true

require "omnes/publication"
require "omnes/publication_context"
require "omnes/registry"
require "omnes/subscription"
require "omnes/unstructured_event"

module Omnes
  # An event bus for the publish/subscribe pattern
  #
  # An instance of this class acts as an event bus middleware for publishers of
  # events and their subscriptions.
  #
  # ```
  # bus = Omnes::Bus.new
  # ```
  #
  # Before being able to work with a given event, its name (a {Symbol}) needs to
  # be registered:
  #
  # ```
  # bus.register(:foo)
  # ```
  #
  # An event can be anything responding to a method `:omes_event_name` which,
  # needless to say, must match with a registered name.
  #
  # Typically, there're two main ways to generate events.
  #
  # An event can be generated at publication time, where you provide its name
  # and a payload to be consumed by its subscribers.
  #
  # ```
  # bus.publish(:foo, bar: :baz)
  # ```
  #
  # In that case, an instance of {Omnes::UnstructuredEvent} is generated
  # under the hood.
  #
  # Unstructured events are straightforward to create and use, but they're
  # harder to debug as they're defined at publication time. On top of that,
  # other features, such as event persistence, can't be reliably built on top of
  # them.
  #
  # You can also publish an instance of a class including {Omnes::Event}. The
  # only fancy thing it provides is an OOTB event name generated based on the
  # class name. See {Omnes::Event} for details.
  #
  # ```
  # class Foo
  #   include Omnes::Event
  #
  #   attr_reader :bar
  #
  #   def initialize
  #     @bar = :baz
  #   end
  # end
  #
  # bus.publish(Foo.new)
  # ```
  #
  # Instance-backed events provide a well-defined structure, and other features,
  # like event persistence, can be added on top of them.
  #
  # Regardless of the type of published event, it's yielded to its subscriptions
  # so that they can do their job:
  #
  # ```
  # bus.subscribe(:foo) do |event|
  #   # event.payload[:bar] or event[:bar] for unstructured events
  #   # event.bar for the event instance example
  # end
  # ```
  #
  # The subscription code can be given as a block (previous example) or as
  # anything responding to a method `#call`.
  #
  # ```
  # class MySubscription
  #   def call(event)
  #     # ...
  #   end
  # end
  #
  # bus.subscribe(:foo, MySubscription.new)
  # ```
  #
  # See also {Omnes::Subscriber} for a more powerful way to define standalone
  # event handlers.
  #
  # You can also create a subscription that will run for all events:
  #
  # ```
  # bus.subscribe_to_all(MySubscription.new)
  # ```
  #
  # Custom matchers can be defined. A matcher is something responding to `#call`
  # and taking the event as an argument. It needs to return `true` or `false` to
  # decide whether the subscription needs to be run for that event.
  #
  # ```
  # matcher ->(event) { event.name.start_with?(:foo) }
  #
  # bus.subscribe_with_matcher(matcher, MySubscription.new)
  # ```
  #
  # For all previous subscription methods, a subscription object is returned.
  # You can supply a subscription id to it to be able to fetch it from the bus
  # later on:
  #
  # ```
  # subscription = bus.subscribe(:foo, MySubscription.new, id: :foo_sub)
  # bus.subscription(:foo_sub) == subscription #=> true
  # ```
  #
  # A subscription can be referenced when you want to unsubscribe:
  #
  # ```
  # bus.unsubscribe(subscription)
  # ```
  class Bus
    # @api private
    def self.EventType(value, **payload)
      case value
      when Symbol
        UnstructuredEvent.new(omnes_event_name: value, payload: payload)
      else
        value
      end
    end

    # @api private
    attr_reader :cal_loc_start,
                :subscriptions

    # @!attribute [r] registry
    #   @return [Omnes::Bus::Registry]
    attr_reader :registry

    def initialize(cal_loc_start: 1, registry: Registry.new, subscriptions: [])
      @cal_loc_start = cal_loc_start
      @registry = registry
      @subscriptions = subscriptions
    end

    # Registers an event name
    #
    # @param event_name [Symbol]
    # @param caller_location [Thread::Backtrace::Location] Caller location
    #   associated to the registration. Useful for debugging (shown in error
    #   messages). It defaults to this method's caller.
    #
    # @raise [Omnes::AlreadyRegisteredEventError] when the event is already
    #   registered
    # @raise [Omnes::InvalidEventNameError] when the event is not a {Symbol}
    #
    # @return [Omnes::Registry::Registration]
    def register(event_name, caller_location: caller_locations(cal_loc_start)[0])
      registry.register(event_name, caller_location: caller_location)
    end

    # Publishes an event, running all matching subscriptions
    #
    # @overload publish(event_name, caller_location:, **payload)
    #   @param event_name [Symbol] Name for the generated
    #     {Omnes::UnstructuredEvent} event.
    #   @param **payload [Hash] Payload for the generated
    #     {Omnes::UnstrUnstructuredEvent}
    #
    # @overload publish(event, caller_location:)
    #   @param event [#name] An event instance
    #
    # @param caller_location [Thread::Backtrace::Location] Caller location
    #   associated to the publication. Useful for debugging (shown in error
    #   messages). It defaults to this method's caller.
    #
    # @return [Omnes::Publication] A publication object encapsulating metadata
    #   for the event and the originated subscription executions
    #
    # @raise [Omnes::UnknownEventError] When event name has not been registered
    def publish(event, caller_location: caller_locations(cal_loc_start)[0], **payload)
      publication_time = Time.now.utc
      event = self.class.EventType(event, **payload)
      registry.check_event_name(event.omnes_event_name)
      publication_context = PublicationContext.new(caller_location: caller_location, time: publication_time)
      executions = execute_subscriptions_for_event(event, publication_context)

      Publication.new(
        event: event,
        executions: executions,
        context: publication_context
      )
    end

    # Adds a subscription for a single event
    #
    # @param event_name [Symbol] Name of the event
    # @param callable [#call] Subscription callback taking the event
    # @param id [Symbol] Unique identifier for the subscription
    # @yield [event] Subscription callback if callable is not given
    #
    # @return [Omnes::Subscription]
    #
    # @raise [Omnes::UnknownEventError] When event name has not been registered
    def subscribe(event_name, callable = nil, id: Subscription.random_id, &block)
      registry.check_event_name(event_name)

      subscribe_with_matcher(Subscription::SINGLE_EVENT_MATCHER.curry[event_name], callable, id: id, &block)
    end

    # Adds a subscription for all events
    #
    # @param callable [#call] Subscription callback taking the event
    # @param id [Symbol] Unique identifier for the subscription
    # @yield [event] Subscription callback if callable is not given
    #
    # @return [Omnes::Subscription]
    def subscribe_to_all(callable = nil, id: Subscription.random_id, &block)
      subscribe_with_matcher(Subscription::ALL_EVENTS_MATCHER, callable, id: id, &block)
    end

    # Adds a subscription with given matcher
    #
    # @param matcher [#call] Callable taking the event and returning a boolean
    # @param callable [#call] Subscription callback taking the event
    # @param id [Symbol] Unique identifier for the subscription
    # @yield [event] Subscription callback if callable is not given
    #
    # @return [Omnes::Subscription]
    def subscribe_with_matcher(matcher, callable = nil, id: Subscription.random_id, &block)
      raise DuplicateSubscriptionIdError.new(id: id, bus: self) if subscription(id)

      callback = callable || block
      Subscription.new(matcher: matcher, callback: callback, id: id).tap do |subscription|
        @subscriptions << subscription
      end
    end

    # Removes a subscription
    #
    # @param subscription [Omnes::Subscription]
    def unsubscribe(subscription)
      @subscriptions.delete(subscription)
    end

    # Runs given block performing only a selection of subscriptions
    #
    # That's something useful for testing purposes, as it allows to silence
    # subscriptions that are not part of the system under test.
    #
    # After the block is over, original subscriptions are restored.
    #
    # @param selection [Array<Omnes::Subscription>]
    # @yield Block to run
    #
    # @raise [Omnes::UnknownSubscriptionError] when the subscription is not
    #   known by the bus
    def performing_only(*selection)
      selection.each do |subscription|
        unless subscriptions.include?(subscription)
          raise UnknownSubscriptionError.new(subscription: subscription,
                                             bus: self)
        end
      end
      all_subscriptions = subscriptions
      @subscriptions = selection
      yield
    ensure
      @subscriptions = all_subscriptions
    end

    # Specialized version of {#performing_only} with no subscriptions
    #
    # @see #performing_only
    def performing_nothing(&block)
      performing_only(&block)
    end

    # Fetch a subscription by its identifier
    #
    # @param id [Symbol] Subscription identifier
    #
    # @return [Omnes::Subscription]
    def subscription(id)
      subscriptions.find { |subscription| subscription.id == id }
    end

    # Clears all registered events and subscriptions
    #
    # Useful for code reloading.
    #
    # @return [Omnes::Bus]
    def clear
      tap do
        @subscriptions = []
        @registry = Registry.new
      end
    end

    private

    def execute_subscriptions_for_event(event, publication_context)
      subscriptions_for_event(event).map do |subscription|
        subscription.(event, publication_context)
      end
    end

    def subscriptions_for_event(event_name)
      @subscriptions.select do |subscription|
        subscription.matches?(event_name)
      end
    end
  end
end
