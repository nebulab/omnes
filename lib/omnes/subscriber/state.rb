# frozen_string_literal: true

require "omnes/subscription"
require "omnes/subscriber/callback_builder"
require "omnes/subscriber/errors"

module Omnes
  module Subscriber
    # @api private
    class State
      attr_reader :subscription_definitions, :calling_cache, :autodiscover_strategy

      def initialize(autodiscover_strategy:, subscription_definitions: [], calling_cache: [])
        @subscription_definitions = subscription_definitions
        @calling_cache = calling_cache
        @autodiscover_strategy = autodiscover_strategy
      end

      def call(bus, instance)
        raise MultipleSubscriberSubscriptionAttemptError if already_called?(bus, instance)

        autodiscover_subscription_definitions(bus, instance) unless autodiscover_strategy.nil?

        definitions = subscription_definitions.map { |defn| defn.(bus) }

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

      def autodiscover_subscription_definitions(bus, instance)
        bus.registry.event_names.each do |event_name|
          method_name = autodiscover_strategy.(event_name)
          next unless instance.respond_to?(method_name, true)

          add_subscription_definition do |_bus|
            [Subscription::SINGLE_EVENT_MATCHER.curry[event_name], CallbackBuilder::Method.new(method_name)]
          end
        end
      end

      def subscribe_definitions(definitions, bus, instance)
        matcher_with_callbacks = definitions.map do |(matcher, builder)|
          [matcher, builder.(instance)]
        end

        matcher_with_callbacks.map { |matcher, callback| bus.subscribe_with_matcher(matcher, callback) }
      end
    end
  end
end
