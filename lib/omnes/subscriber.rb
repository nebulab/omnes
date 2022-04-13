# frozen_string_literal: true

require "omnes/subscriber/adapter"
require "omnes/subscriber/state"
require "omnes/subscription"

module Omnes
  # Supscriptions provider for a {Omnes::Bus}
  #
  # This module allows an including class to use its context to create event
  # handlers.
  #
  # In its simplest form, you can match an event to a method in the class.
  #
  # ```
  # class MySubscriber
  #   include Omnes::Subscriber
  #
  #   handle :foo, with: :my_handler
  #
  #   def my_handler(event)
  #     # do_something
  #   end
  # end
  # ```
  #
  # Equivalent to the subscribe methods in {Omnes::Bus}, you can also subscribe
  # to all events or use a custom matcher:
  #
  # ```
  # class MySubscriber
  #   include Omnes::Subscriber
  #
  #   handle_all                      with: :my_handler_one
  #   handle_with_matcher my_matcher, with: :my_handler_two
  #
  #   def my_handler_one(event)
  #     # do_something
  #   end
  #
  #   def my_handler_two(event)
  #     # do_something_else
  #   end
  # end
  # ```
  #
  # Another option is to let the event handlers be automatically discovered. You
  # need to enable the `autodiscover` feature and prefix the event name with
  # `on_` for your handler name.
  #
  # ```
  # class MySubscriber
  #   include Omnes::Subscriber[
  #     autodiscover: true
  #   ]
  #
  #   def on_foo(event)
  #     # do_something
  #   end
  # end
  # ```
  #
  # If you prefer, you can make `autodiscover` on by default:
  #
  # ```
  # Omnes.config.subscriber.autodiscover = true
  # ```
  #
  # You can specify your own autodiscover strategy. It must be something
  # callable, transforming the event name into the handler name.
  #
  # ```
  # AUTODISCOVER_STRATEGY = ->(event_name) { event_name }
  #
  # class MySubscriber
  #   include Omnes::Subscriber[
  #     autodiscover: true,
  #     autodiscover_strategy: AUTODISCOVER_STRATEGY
  #   ]
  #
  #   def foo(event)
  #     # do_something
  #   end
  # end
  # ```
  # You're not limited to using method names as event handlers. You can create
  # your own adapters from the subscriber instance context.
  #
  # ```
  # ADAPTER = lambda do |instance, event|
  #   event.foo? ? instance.foo_true(event) : instance.foo_false(event)
  # end
  #
  # class MySubscriber
  #   include Omnes::Subscriber
  #
  #   handle :my_event, with: ADAPTER
  #
  #   def foo_true(event)
  #     # do_something
  #   end
  #
  #   def foo_false(event)
  #     # do_something_else
  #   end
  # end
  # ```
  #
  # Subscriber adapters can be leveraged to build integrations with background
  # job libraries. See {Omnes::Subscriber::Adapter} for what comes shipped with
  # the library.
  #
  # Once you've defined the event handlers, you can subscribe to a {Omnes::Bus}
  # instance:
  #
  # ```
  # MySubscriber.new.subscribe_to(bus)
  # ```
  #
  # Notice that a subscriber instance can only be subscribed once to the same
  # bus. However, you can subscribe distinct instances to the same bus or the
  # same instance to different buses.
  module Subscriber
    extend Configurable

    # @api private
    ON_PREFIX_STRATEGY = ->(event_name) { :"on_#{event_name}" }

    setting :autodiscover, default: false
    setting :autodiscover_strategy, default: ON_PREFIX_STRATEGY
    nest_config Adapter

    # Includes with options
    #
    # ```
    # include Omnes::Subscriber[autodiscover: true]
    # ```
    #
    # Use regular `include Omnes::Subscriber` in case you want to use the
    # defaults (which can be changed through configuration).
    #
    # @param autodiscover [Boolean]
    # @param autodiscover_strategy [#call]
    def self.[](autodiscover: config.autodiscover, autodiscover_strategy: config.autodiscover_strategy)
      Module.new(autodiscover_strategy: autodiscover ? autodiscover_strategy : nil)
    end

    # @api private
    def self.included(klass)
      klass.include(self.[])
    end

    # @api private
    class Module < ::Module
      attr_reader :autodiscover_strategy

      def initialize(autodiscover_strategy:)
        @autodiscover_strategy = autodiscover_strategy
        super()
      end

      def included(klass)
        klass.instance_variable_set(:@_mutex, Mutex.new)
        klass.instance_variable_set(:@_state, State.new(autodiscover_strategy: autodiscover_strategy))
        klass.extend(ClassMethods)
        klass.include(InstanceMethods)
      end
    end

    # Instance methods included in a {Omnes::Subscriber}
    module InstanceMethods
      # Subscribes event handlers to a bus
      #
      # @param bus [Omnes::Bus]
      #
      # @return [Omnes::Subscriber::Subscribers]
      #
      # @raise [Omnes::Subscriber::UnknownMethodSubscriptionAttemptError] when
      #   subscribing a method that doesn't exist
      # @raise [Omnes::Subscriber::PrivateMethodSubscriptionAttemptError] when
      #   trying to subscribe a method that is private
      # @raise [Omnes::Subscriber::DuplicateSubscriptionAttemptError] when
      #   trying to subscribe to the same event with the same method more than once
      def subscribe_to(bus)
        self.class.instance_variable_get(:@_state).public_send(:call, bus, self)
      end
    end

    # Included DSL methods for a {Omnes::Subscriber}
    module ClassMethods
      # Match a single event name
      #
      # @param event_name [Symbol]
      # @param with [Symbol, #call] Public method in the class or an adapter
      # @param id [Symbol] Unique identifier for the subscription
      def handle(event_name, with:, id: Subscription.random_id)
        @_mutex.synchronize do
          @_state.add_subscription_definition do |bus, instance|
            bus.registry.check_event_name(event_name)
            [Subscription::SINGLE_EVENT_MATCHER.curry[event_name], Adapter.Type(with), State.IdType(id).(instance)]
          end
        end
      end

      # Handles all events
      #
      # @param with [Symbol, #call] Public method in the class or an adapter
      # @param id [Symbol] Unique identifier for the subscription
      def handle_all(with:, id: Subscription.random_id)
        @_mutex.synchronize do
          @_state.add_subscription_definition do |_bus, instance|
            [Subscription::ALL_EVENTS_MATCHER, Adapter.Type(with), State.IdType(id).(instance)]
          end
        end
      end

      # Handles events with a custom matcher
      #
      # @param matcher [#call]
      # @param with [Symbol, #call] Public method in the class or an adapter
      # @param id [Symbol] Unique identifier for the subscription
      def handle_with_matcher(matcher, with:, id: Subscription.random_id)
        @_mutex.synchronize do
          @_state.add_subscription_definition do |_bus, instance|
            [matcher, Adapter.Type(with), State.IdType(id).(instance)]
          end
        end
      end
    end
  end
end
