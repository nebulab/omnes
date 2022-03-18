# frozen_string_literal: true

module Omnes
  module Subscriber
    module Adapter
      # [Sidekiq](https://sidekiq.org/) adapter
      #
      # Builds subscription to be processed as Sidekiq's background jobs.
      #
      # The return value of a `payload` method in the event is what is given to
      # the `#perform` instance method. You need to make sure that's something
      # serializable.
      #
      # ```
      # class MySubscriber
      #   include Omnes::Subscriber
      #   include Sidekiq::Job
      #
      #   handle :my_event, with: Adapter::Sidekiq
      #
      #   def perform(payload)
      #     # do_something
      #   end
      # end
      #
      # bus = Omnes::Bus.new
      # bus.register(:my_event)
      # bus.publish(:my_event, "foo" => "bar")
      # ```
      #
      # You can delay the callback execution from the publication time with the
      # {.it} method (analogous to {Sidekiq::Job.perform_in}).
      #
      # @example
      #   handle :my_event, with: Adapter::Sidekiq.in(60)
      module Sidekiq
        # @api private
        def self.call(instance, event)
          instance.class.perform_async(event.payload)
        end

        # @param seconds [Integer]
        def self.in(seconds)
          lambda do |instance, event|
            instance.class.perform_in(seconds, event.payload)
          end
        end
      end
    end
  end
end
