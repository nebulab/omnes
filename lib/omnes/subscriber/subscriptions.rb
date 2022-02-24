# frozen_string_literal: true

module Omnes
  module Subscriber
    # Collection of {Omnes::Subscription}
    class Subscriptions
      # @!attribute [r] subscriptions
      #   @return [Array<Omnes::Subscription>] All subscriptions
      attr_reader :subscriptions

      # @api private
      def initialize(subscriptions:)
        @subscriptions = subscriptions
      end

      # Method names subscribed to a given event name
      #
      # @param event_name [Symbol]
      #
      # @return [Array<Symbol>]
      def method_names(event_name:)
        subscriptions.filter_map do |subscription|
          (subscription.pattern == event_name) && subscription.block.name
        end
      end

      # Event names subscribed by a given method
      #
      # @param method_name [Symbol]
      #
      # @return [Array<Symbol>]
      def event_names(method_name:)
        subscriptions.filter_map do |subscription|
          (subscription.block.name == method_name) && subscription.pattern
        end
      end
    end
  end
end
