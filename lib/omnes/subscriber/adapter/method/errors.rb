# frozen_string_literal: true

require "omnes/errors"

module Omnes
  module Subscriber
    module Adapter
      class Method
        # Raised when trying to subscribe to a missing method
        class UnknownMethodSubscriptionAttemptError < Omnes::Error
          attr_reader :method_name

          # @api private
          def initialize(method_name:)
            @method_name = method_name
            super(default_message)
          end

          private

          def default_message
            <<~MSG
              You tried to subscribe an unexisting "#{method_name}" method. Event
              handlers need to be public methods on the subscriber class.
            MSG
          end
        end

        # Raised when trying to subscribe to a private method
        class PrivateMethodSubscriptionAttemptError < Omnes::Error
          attr_reader :method_name

          # @api private
          def initialize(method_name:)
            @method_name = method_name
            super(default_message)
          end

          private

          def default_message
            <<~MSG
              You tried to subscribe "#{method_name}" private method. Event handlers
              need to be public methods on the subscriber class.
            MSG
          end
        end
      end
    end
  end
end
