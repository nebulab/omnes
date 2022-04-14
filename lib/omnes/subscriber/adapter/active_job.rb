# frozen_string_literal: true

require "omnes/configurable"

module Omnes
  module Subscriber
    module Adapter
      # [ActiveJob](https://edgeguides.rubyonrails.org/active_job_basics.html) adapter
      #
      # Builds subscription to be processed as ActiveJob background jobs.
      #
      # ActiveJob requires that the argument passed to `#perform` is
      # serializable. By default, the result of calling `#payload` in the event
      # is taken.
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
      # However, you can configure how the event is serialized thanks to the
      # `serializer:` option. It needs to be something callable taking the
      # event as argument:
      #
      # ```
      # handle :my_event, with: Adapter::ActiveJob[serializer: :serialized_payload.to_proc]
      # ```
      #
      # You can also globally configure the default serializer:
      #
      # ```
      # Omnes.config.subscriber.adapter.active_job.serializer = :serialized_payload.to_proc
      # ```
      module ActiveJob
        extend Configurable

        setting :serializer, default: :payload.to_proc

        # @param serializer [#call]
        def self.[](serializer: config.serializer)
          Instance.new(serializer: serializer)
        end

        # @api private
        def self.call(instance, event, publication_context)
          self.[].(instance, event, publication_context)
        end

        # @api private
        class Instance
          attr_reader :serializer

          def initialize(serializer:)
            @serializer = serializer
          end

          def call(instance, event, publication_context)
            if Subscription.takes_publication_context?(instance.method(:perform))
              instance.class.perform_later(serializer.(event), publication_context.serialized)
            else
              instance.class.perform_later(serializer.(event))
            end
          end
        end
      end
    end
  end
end
