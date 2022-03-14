# frozen_string_literal: true

module Omnes
  module Subscriber
    module Adapter
      # [Sidekiq](https://sidekiq.org/) adapter
      #
      # Builds subscription callbacks to be processed as Sidekiq's background
      # jobs.
      #
      # The return value of a `payload` method in the event is what is given to
      # the `#perform` instance method. You need to make sure that's something
      # serializable.
      #
      # @example
      #   class MySubscriber
      #     include Omnes::Subscriber
      #     include Sidekiq::Job
      #
      #     handle :my_event, with: Adapter::Sidekiq
      #
      #     def perform(payload)
      #       # do_something
      #     end
      #   end
      #
      # You can delay the callback execution from the publication time with the
      # {.it} method (analogous to {Sidekiq::Job.perform_in}).
      #
      # @example
      #   handle :my_event, with: Adapter::Sidekiq.in(60)
      module Sidekiq
        def self.call(instance, event)
          instance.class.perform_async(event.payload)
        end

        def self.in(seconds)
          lambda do |instance, event|
            instance.class.perform_in(seconds, event.payload)
          end
        end
      end
    end
  end
end
