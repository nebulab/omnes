# frozen_string_literal: true

require "omnes/subscriber/adapter/method/errors"

module Omnes
  module Subscriber
    module Adapter
      # Builds a callback from a method of the instance
      #
      # You can use an instance of this class as the adapter:
      #
      # ```ruby
      # handle :foo, with: Adapter::Method.new(:foo)
      # ```
      #
      # However, you can short-circuit with a {Symbol}.
      #
      # ```ruby
      # handle :foo, with: :foo
      # ```
      class Method
        attr_reader :name

        def initialize(name)
          @name = name
        end

        # @api private
        def call(instance)
          check_method(instance)

          instance.method(name)
        end

        private

        def check_method(instance)
          raise PrivateMethodSubscriptionAttemptError.new(method_name: name) if instance.private_methods.include?(name)

          raise UnknownMethodSubscriptionAttemptError.new(method_name: name) unless instance.methods.include?(name)
        end
      end
    end
  end
end
