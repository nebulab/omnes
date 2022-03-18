# frozen_string_literal: true

module Omnes
  module Subscriber
    module Adapter
      # [ActiveJob](https://edgeguides.rubyonrails.org/active_job_basics.html) adapter
      #
      # Builds subscription to be processed as ActiveJob background jobs.
      #
      # The return value of a `payload` method in the event is what is given to
      # the `#perform` instance method. You need to make sure that's something
      # serializable.
      #
      # ```
      # class MyJob < ActiveJob
      #   include Omnes::Subscriber
      #
      #   handle :my_event, with: Adapter::ActiveJob
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
      module ActiveJob
        # @api private
        def self.call(instance, event)
          instance.class.perform_later(event.payload)
        end
      end
    end
  end
end
