# frozen_string_literal: true

require "spec_helper"
require "omnes/subscriber/adapter/method"

RSpec.describe Omnes::Subscriber::Adapter::Method do
  let(:subscriber_class) do
    Class.new do
      include Omnes::Subscriber

      attr_reader :value

      def initialize
        @value = nil
      end
    end
  end
  let(:bus) { Omnes::Bus.new }

  it "uses given method as handler" do
    subscriber_class.class_eval do
      include Omnes::Subscriber

      handle :foo, with: :foo

      def foo(event)
        @value = event[:value]
      end
    end

    bus.register(:foo)
    subscriber = subscriber_class.new
    subscriber.subscribe_to(bus)
    bus.publish(:foo, value: :bar)

    expect(subscriber.value).to be(:bar)
  end

  it "provides publication context if the method takes a second parameter" do
    subscriber_class.class_eval do
      include Omnes::Subscriber

      handle :foo, with: :foo

      def foo(_event, publication_context)
        @value = publication_context
      end
    end

    bus.register(:foo)
    subscriber = subscriber_class.new
    subscriber.subscribe_to(bus)
    bus.publish(:foo, value: :bar)

    expect(subscriber.value.is_a?(Omnes::PublicationContext)).to be(true)
  end

  it "raises when method is private" do
    subscriber_class.class_eval do
      include Omnes::Subscriber

      handle :foo, with: :foo

      private def foo(_event); end
    end

    bus.register(:foo)
    subscriber = subscriber_class.new

    expect {
      subscriber.subscribe_to(bus)
    }.to raise_error(
      described_class::PrivateMethodSubscriptionAttemptError,
      /"foo" private method/m
    )
  end

  it "raises when method doesn't exist" do
    subscriber_class.class_eval do
      include Omnes::Subscriber

      handle :foo, with: :foo
    end

    bus.register(:foo)
    subscriber = subscriber_class.new

    expect {
      subscriber.subscribe_to(bus)
    }.to raise_error(
      described_class::UnknownMethodSubscriptionAttemptError,
      /"foo" method/m
    )
  end
end
