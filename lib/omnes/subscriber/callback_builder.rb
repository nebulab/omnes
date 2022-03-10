# frozen_string_literal: true

require "omnes/subscriber/callback_builder/method"

module Omnes
  module Subscriber
    # Builders of {Omnes::Subscription}'s callbacks
    #
    # Builders need to implement a method `#call` taking the instance of the
    # {Omnes::Subscriber). They need to create an
    # {Omnes::Subscripiton#callback}. See {Omnes::Bus#subscribe}'s callable
    # argument for details.
    module CallbackBuilder
      # @api private
      # TODO: Simplify when currying the builder by just taking the `#call`
      # method regardless of the value being a callable object or a proc. Waiting
      # for https://bugs.ruby-lang.org/issues/18620
      #   > builder.method(:call).curry[instance]
      def self.Type(value)
        case value
        when Symbol
          Type(Method.new(value))
        when Proc
          value
        else
          value.method(:call)
        end
      end
    end
  end
end
