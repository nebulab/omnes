# frozen_string_literal: true

require "omnes/configurable"
require "omnes/subscriber/adapter/active_job"
require "omnes/subscriber/adapter/method"
require "omnes/subscriber/adapter/sidekiq"

module Omnes
  module Subscriber
    # Adapters to build {Omnes::Subscription}'s callbacks
    #
    # Adapters need to implement a method `#call` taking the instance of
    # {Omnes::Subscriber} and the event.
    #
    # Alternatively, they can be curried and only take the instance as an
    # argument, returning a one-argument callable taking the event.
    module Adapter
      extend Configurable

      nest_config Sidekiq
      nest_config ActiveJob

      # @api private
      # TODO: Simplify when when we can take callables and Proc in a polymorphic
      # way: https://bugs.ruby-lang.org/issues/18644
      #   > builder.to_proc.curry[instance]
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
