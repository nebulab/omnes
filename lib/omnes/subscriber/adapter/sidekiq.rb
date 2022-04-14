# frozen_string_literal: true

require "omnes/configurable"

module Omnes
  module Subscriber
    module Adapter
      # [Sidekiq](https://sidekiq.org/) adapter
      #
      # Builds subscription to be processed as Sidekiq's background jobs.
      #
      # Sidekiq requires that the argument passed to `#perform` is serializable.
      # By default, the result of calling `#payload` in the event is taken.
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
      # However, you can configure how the event is serialized thanks to the
      # `serializer:` option. It needs to be something callable taking the
      # event as argument:
      #
      # ```
      # handle :my_event, with: Adapter::Sidekiq[serializer: :serialized_payload.to_proc]
      # ```
      #
      # You can also globally configure the default serializer:
      #
      # ```
      # Omnes.config.subscriber.adapter.sidekiq.serializer = :serialized_payload.to_proc
      # ```
      #
      # You can delay the callback execution from the publication time with the
      # {.in} method (analogous to {Sidekiq::Job.perform_in}).
      #
      # @example
      #   handle :my_event, with: Adapter::Sidekiq.in(60)
      module Sidekiq
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

        # @param seconds [Integer]
        def self.in(seconds)
          self.[].in(seconds)
        end

        # @api private
        class Instance
          attr_reader :serializer

          def initialize(serializer:)
            @serializer = serializer
          end

          def call(instance, event, publication_context)
            if takes_publication_context?(instance)
              instance.class.perform_async(serializer.(event), publication_context.serialized)
            else
              instance.class.perform_async(serializer.(event))
            end
          end

          def in(seconds)
            lambda do |instance, event, publication_context|
              if takes_publication_context?(instance)
                instance.class.perform_in(seconds, serializer.(event), publication_context.serialized)
              else
                instance.class.perform_in(seconds, serializer.(event))
              end
            end
          end

          private

          def takes_publication_context?(instance)
            Subscription.takes_publication_context?(instance.method(:perform))
          end
        end
      end
    end
  end
end
