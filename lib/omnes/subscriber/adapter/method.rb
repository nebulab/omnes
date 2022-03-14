# frozen_string_literal: true

require "omnes/subscriber/adapter/method/errors"

module Omnes
  module Subscriber
    module Adapter
      # Builds a callback from a method of the instance
      class Method
        attr_reader :name

        def initialize(name)
          @name = name
        end

        def call(instance)
          check_method(instance)

          ->(event) { instance.method(name).(event) }
        end

        def check_method(instance)
          raise PrivateMethodSubscriptionAttemptError.new(method_name: name) if instance.private_methods.include?(name)

          raise UnknownMethodSubscriptionAttemptError.new(method_name: name) unless instance.methods.include?(name)
        end
      end
    end
  end
end
