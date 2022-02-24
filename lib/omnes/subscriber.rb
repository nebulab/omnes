# frozen_string_literal: true

require 'omnes/subscriber/state'

module Omnes
  # Supscription provider for an {Omnes::Bus}
  #
  # You can include this module in a class to use its methods as handlers for an
  # event bus.
  #
  # There're two ways to specify event handlers.
  #
  # 1. Match an event name with a method name prepended with `:on_`.
  #
  # @example
  #   require 'omnes/subscriber'
  #
  #   class MySubscriber
  #     include Omnes::Subscriber
  #
  #     def on_foo(event)
  #       # do_something
  #     end
  #   end
  #
  # 2. Use the `handle` class method.
  #
  # @example
  #   require 'omnes/subscriber'
  #
  #   class MySubscriber
  #     include Omnes::Subscriber
  #
  #     handle :foo, with: :my_method
  #
  #     def my_method(event)
  #       # do_something
  #     end
  #   end
  #
  # Both ways can be used at the same time.
  #
  # You can call `#subscribe_to` on the instance to activate the subscriptions:
  #
  # @example
  #   require 'omnes/bus'
  #
  #   bus = Omnes::Bus.new
  #   bus.register(:foo)
  #   MySubscriber.new.subscribe_to(bus)
  #
  # Nuances to be took into account:
  #
  # - You can subscribe a method to different events.
  # - You can subscribe different methods to the same event.
  # - You can't subscribe the same method to the same event more than once.
  # - You can't subscribe private methods.
  # - Once you've called `#subscribe_to`, you can't re-subscribe again.
  module Subscriber
    # @api private
    def self.included(klass)
      klass.instance_variable_set(:@_mutex, Mutex.new)
      klass.instance_variable_set(:@_state, State.new)
      klass.extend(ClassMethods)
    end

    # Subscribes defined & autodiscovered handlers to a bus
    #
    # @param bus [Omnes::Bus]
    #
    # @return [Omnes::Subscriber::Subscribers]
    #
    # @raise [Omnes::Subscriber::UnknownMethodSubscriptionAttemptError] when
    # subscribing a method that doesn't exist
    # @raise [Omnes::Subscriber::PrivateMethodSubscriptionAttemptError] when
    # trying to subscribe a method that is private
    # @raise [Omnes::Subscriber::DuplicateSubscriptionAttemptError] when
    # trying to subscribe to the same event with the same method more than once
    def subscribe_to(bus)
      self.class.instance_variable_get(:@_state).public_send(:call, bus, self)
    end

    # Included DSL
    module ClassMethods
      # Manual definition of an event handler
      #
      # @param event_name [Symbol]
      # @param with [Symbol] Public method in the class
      #
      # @raise [FrozenError] when an instance of the class has already called
      # its {#subscribe_to} method.
      def handle(event_name, with:)
        @_mutex.synchronize do
          @_state.add_manual_definition(event_name, with)
        end
      end
    end
  end
end
