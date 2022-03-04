# frozen_string_literal: true

require "omnes/subscription"
require "omnes/subscriber/errors"
require "omnes/subscriber/subscriptions"

module Omnes
  module Subscriber
    # @api private
    class State
      attr_reader :subscription_definitions, :calling_cache

      def initialize(subscription_definitions: [], calling_cache: [])
        @subscription_definitions = subscription_definitions
        @calling_cache = calling_cache
      end

      def call(bus, instance)
        raise FrozenSubscriberError if already_called?(bus, instance)

        autodiscover_subscription_definitions(bus, instance)

        definitions = subscription_definitions.map { |defn| defn.(bus) }
        check_definitions(definitions, bus, instance)

        Subscriptions.new(
          bus: bus,
          subscriptions: subscribe_definitions(definitions, bus, instance)
        ).tap { mark_as_called(bus, instance) }
      end

      def add_subscription_definition(&block)
        @subscription_definitions << block
      end

      private

      def already_called?(bus, instance)
        calling_cache.include?([bus, instance])
      end

      def mark_as_called(bus, instance)
        @calling_cache << [bus, instance]
      end

      def autodiscover_subscription_definitions(bus, instance)
        bus.registry.event_names.each do |event_name|
          method_name = :"on_#{event_name}"
          next unless instance.respond_to?(method_name, true)

          add_subscription_definition do |_bus|
            [Subscription::SINGLE_EVENT_STRATEGY.curry[event_name], method_name]
          end
        end
      end

      def check_definitions(definitions, bus, instance)
        definitions.each do |_strategy, method_name|
          check_method(method_name, instance)
        end
        check_duplicates(bus, definitions)
      end

      def check_duplicates(bus, definitions)
        all_events = bus.registry.event_names
        duplicates = duplicates(definitions, all_events)

        raise DuplicateSubscriptionAttemptError.new(duplicates: duplicates) if duplicates.any?
      end

      def duplicates(definitions, events)
        events_with_methods = definitions.map do |(strategy, method)|
          event_names = events.select { |event| strategy.(event) }
          event_names.map { |event_name| [event_name, method] }
        end.flatten(1)

        events_with_methods.group_by(&:itself).filter_map { |k, v| v.count > 1 && k }
      end

      def check_method(method_name, instance)
        if instance.private_methods.include?(method_name)
          raise PrivateMethodSubscriptionAttemptError.new(method_name: method_name)
        end
        return if instance.methods.include?(method_name)

        raise UnknownMethodSubscriptionAttemptError.new(method_name: method_name)
      end

      def subscribe_definitions(definitions, bus, instance)
        definitions.map do |(strategy, method_name)|
          bus.subscribe_with_strategy(strategy, instance.method(method_name))
        end
      end
    end
  end
end
