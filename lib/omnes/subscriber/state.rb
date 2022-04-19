# frozen_string_literal: true

require "omnes/subscriber/adapter"
require "omnes/subscriber/errors"
require "omnes/subscription"

module Omnes
  module Subscriber
    # @api private
    class State
      attr_reader :subscription_definitions, :calling_cache, :autodiscover_strategy

      # @api private
      def self.IdType(value)
        value.respond_to?(:call) ? value : ->(_instance) { value }
      end

      def initialize(autodiscover_strategy:, subscription_definitions: [], calling_cache: [])
        @subscription_definitions = subscription_definitions
        @calling_cache = calling_cache
        @autodiscover_strategy = autodiscover_strategy
      end

      def call(bus, instance)
        raise MultipleSubscriberSubscriptionAttemptError if already_called?(bus, instance)

        all_subscription_definitions = subscription_definitions + autodiscovered_subscription_definitions(bus, instance)

        definitions = all_subscription_definitions.map { |defn| defn.(bus, instance) }

        subscribe_definitions(definitions, bus, instance).tap do
          mark_as_called(bus, instance)
        end
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

      def autodiscovered_subscription_definitions(bus, instance)
        return [] unless autodiscover_strategy

        bus.registry.event_names.reduce([]) do |defs, event_name|
          method_name = autodiscover_strategy.(event_name)
          if instance.respond_to?(method_name, true)
            [
              *defs,
              autodiscovered_subscription_definition(event_name, method_name)
            ]
          else
            defs
          end
        end
      end

      def autodiscovered_subscription_definition(event_name, method_name)
        lambda do |_bus, _instance|
          [
            Subscription::SINGLE_EVENT_MATCHER.curry[event_name],
            Adapter.Type(Adapter::Method.new(method_name)),
            Subscription.random_id
          ]
        end
      end

      def subscribe_definitions(definitions, bus, instance)
        matcher_with_callbacks = definitions.map do |(matcher, adapter, id)|
          [matcher, adapter.curry[instance], id]
        end

        matcher_with_callbacks.map { |matcher, callback, id| bus.subscribe_with_matcher(matcher, callback, id: id) }
      end
    end
  end
end
