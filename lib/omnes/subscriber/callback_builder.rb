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
      def self.Type(value)
        case value
        when Symbol
          Method.new(value)
        else
          value
        end
      end
    end
  end
end
