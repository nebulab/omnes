# frozen_string_literal: true

require 'omnes/errors'

module Omnes
  module Subscriber
    # Raised when trying to subscribe to a missing method
    class UnknownMethodSubscriptionAttemptError < Omnes::Error
      attr_reader :event_name, :method_name

      # @api private
      def initialize(event_name:, method_name:)
        @event_name = event_name
        @method_name = method_name
        super(default_message)
      end

      private

      def default_message
        <<~MSG
          You tried to subscribe to the event "#{event_name}" through an
          unexisting "#{method_name}" method. Event handlers need to be public
          methods on the subscriber class.
        MSG
      end
    end

    # Raised when trying to subscribe to a private method
    class PrivateMethodSubscriptionAttemptError < Omnes::Error
      attr_reader :event_name, :method_name

      # @api private
      def initialize(event_name:, method_name:)
        @event_name = event_name
        @method_name = method_name
        super(default_message)
      end

      private

      def default_message
        <<~MSG
          You tried to subscribe to the event "#{event_name}" through the
          "#{method_name}" private method. Event handlers need to be public
          methods on the subscriber class.
        MSG
      end
    end

    # Raised when trying to subscribe multiple times an event to the same method
    class DuplicateSubscriptionAttemptError < Omnes::Error
      attr_reader :duplicates

      # @api private
      def initialize(duplicates:)
        @duplicates = duplicates
        super(default_message)
      end

      private

      def default_message
        <<~MSG
          It's not allowed to subscribe more than once to the same event with
          the same method. Please, remove the extra definitions for the following pairs of event name and method:
          #{duplicates.map { |(event_name, method_name)| "#{event_name} / #{method_name}" }.join("\n")}
        MSG
      end
    end

    # Raised when calling {Omnes::Subscriber#subscribe_to} multiple times
    class FrozenSubscriberError < Omnes::Error
      # @api private
      def initialize
        super(default_message)
      end

      private

      def default_message
        <<~MSG
          Omnes::Subscriber#subscribe_to method can only be called once.
        MSG
      end
    end
  end
end
