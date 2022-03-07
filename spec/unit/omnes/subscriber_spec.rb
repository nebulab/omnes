# frozen_string_literal: true

require "omnes/bus"
require "omnes/subscriber"

RSpec.describe Omnes::Subscriber do
  let(:subscriber_class) { Class.new.include(described_class) }
  let(:bus) { Omnes::Bus.new }

  describe "#subscribe_to" do
    it "autodiscovers and subscribes methods matching registered events" do
      bus.register(:foo)
      subscriber_class.class_eval do
        def on_foo(_event)
          __method__
        end
      end

      subscriber_class.new.subscribe_to(bus)

      subscription = bus.subscriptions[0]
      expect(subscription.matches?(:foo)).to be(true)
      expect(subscription.callback.(:event)).to be(:on_foo)
    end

    it "can use custom strategy to autodiscover" do
      bus.register(:foo)
      subscriber_class = Class.new do
        include Omnes::Subscriber[autodiscover_strategy: ->(event_name) { :"left_#{event_name}_right" }]

        def left_foo_right(_event)
          __method__
        end
      end

      subscriber_class.new.subscribe_to(bus)

      subscription = bus.subscriptions[0]
      expect(subscription.matches?(:foo)).to be(true)
      expect(subscription.callback.(:event)).to be(:left_foo_right)
    end

    it "subscribes with manually specified single event handlers" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :bar

        def bar(_event)
          __method__
        end
      end

      subscriber_class.new.subscribe_to(bus)

      subscription = bus.subscriptions[0]
      expect(subscription.matches?(:foo)).to be(true)
      expect(subscription.callback.(:event)).to be(:bar)
    end

    it "subscribes with manually specified global handlers" do
      bus.register(:bar)
      subscriber_class.class_eval do
        handle_all with: :bar

        def bar(_event)
          __method__
        end
      end

      subscriber_class.new.subscribe_to(bus)

      subscription = bus.subscriptions[0]
      expect(subscription.matches?(:foo)).to be(true)
      expect(subscription.callback.(:event)).to be(:bar)
    end

    it "subscribes with custom strategy" do
      true_strategy = ->(_candidate) { true }
      bus.register(:bar)
      subscriber_class.class_eval do
        handle_with_strategy true_strategy, with: :bar

        def bar(_event)
          __method__
        end
      end

      subscriber_class.new.subscribe_to(bus)

      subscription = bus.subscriptions[0]
      expect(subscription.matches?(:foo)).to be(true)
      expect(subscription.callback.(:event)).to be(:bar)
    end

    it "raises when trying to subscribe to an autodiscovered private method" do
      bus.register(:foo)
      subscriber_class.class_eval do
        private def on_foo; end
      end

      expect {
        subscriber_class.new.subscribe_to(bus)
      }.to raise_error(
        described_class::PrivateMethodSubscriptionAttemptError,
        /"on_foo" private method/m
      )
    end

    it "raises when trying to subscribe to a private method with manual definition" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :bar

        private def bar; end
      end

      expect {
        subscriber_class.new.subscribe_to(bus)
      }.to raise_error(
        described_class::PrivateMethodSubscriptionAttemptError,
        /"bar" private method/m
      )
    end

    it "returns a Subscriptions instance" do
      bus.register(:foo)
      subscriber_class.class_eval do
        def on_foo; end
      end

      subscriptions = subscriber_class.new.subscribe_to(bus)

      expect(subscriptions).to be_a(described_class::Subscriptions)
    end

    it "can subscribe different methods to the same event with manual definition" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :foo
        handle :foo, with: :bar

        def foo; end
        def bar; end
      end

      subscriptions = subscriber_class.new.subscribe_to(bus)

      expect(subscriptions.method_names(event_name: :foo)).to match_array(%i[foo bar])
    end

    it "can subscribe different methods to the same event mixing autodescovering and manual definition" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :bar

        def on_foo; end
        def bar; end
      end

      subscriptions = subscriber_class.new.subscribe_to(bus)

      expect(subscriptions.method_names(event_name: :foo)).to match_array(%i[on_foo bar])
    end

    it "can subscribe the same method to different events with manual definition" do
      bus.register(:foo)
      bus.register(:bar)
      subscriber_class.class_eval do
        handle :foo, with: :foobar
        handle :bar, with: :foobar

        def foobar; end
      end

      subscriptions = subscriber_class.new.subscribe_to(bus)

      expect(subscriptions.event_names(method_name: :foobar)).to match_array(%i[foo bar])
    end

    it "can subscribe the same method to different events mixing autodescovering and manual definition" do
      bus.register(:foo)
      bus.register(:bar)
      subscriber_class.class_eval do
        handle :bar, with: :on_foo

        def on_foo; end
      end

      subscriptions = subscriber_class.new.subscribe_to(bus)

      expect(subscriptions.event_names(method_name: :on_foo)).to match_array(%i[foo bar])
    end

    it "raises when trying to subscribe the same method twice to the same event with manual definition" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :foo
        handle :foo, with: :foo

        def foo; end
      end

      expect {
        subscriber_class.new.subscribe_to(bus)
      }.to raise_error(
        described_class::DuplicateSubscriptionAttemptError,
        %r{foo / foo}m
      )
    end

    it "raises when trying to subscribe the same method twice to the same event mixing autodescovering and manual" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :on_foo

        def on_foo; end
      end

      expect {
        subscriber_class.new.subscribe_to(bus)
      }.to raise_error(
        described_class::DuplicateSubscriptionAttemptError,
        %r{foo / on_foo}m
      )
    end

    it "raises when trying to subscribe to a method that doesn't exist" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :bar
      end

      expect {
        subscriber_class.new.subscribe_to(bus)
      }.to raise_error(
        described_class::UnknownMethodSubscriptionAttemptError,
        /"bar" method/m
      )
    end

    it "raises when trying to subscribe to an unregistered event" do
      subscriber_class.class_eval do
        handle :foo, with: :foo

        def foo; end
      end

      expect {
        subscriber_class.new.subscribe_to(bus)
      }.to raise_error(
        Omnes::UnknownEventError
      )
    end

    it "doesn't add any subscription if there's an error" do
      bus.register(:foo)
      bus.register(:bar)
      subscriber_class.class_eval do
        handle :foo, with: :foo
        handle :bar, with: :bar

        def foo; end
      end

      expect {
        subscriber_class.new.subscribe_to(bus)
      }.to raise_error(described_class::UnknownMethodSubscriptionAttemptError)

      expect(bus.subscriptions.count).to be(0)
    end

    it "can subscriber multiple instances to the same bus" do
      bus.register(:foo)
      subscriber_class.class_eval do
        attr_reader :value

        handle :foo, with: :foo

        def initialize(value)
          @value = value
        end

        def foo(_event)
          value
        end
      end

      subscriber_class.new(1).subscribe_to(bus)
      subscriber_class.new(2).subscribe_to(bus)

      expect(bus.publish(:foo).executions.map(&:result)).to match_array([1, 2])
    end

    it "can subscriber the same instance to different buses" do
      bus_one = Omnes::Bus.new
      bus_two = Omnes::Bus.new
      [bus_one, bus_two].each { |bus| bus.register(:foo) }
      subscriber_class.class_eval do
        handle :foo, with: :foo

        def foo; end
      end
      subscriber = subscriber_class.new

      subscriptions_from_one = subscriber.subscribe_to(bus_one)
      subscriptions_from_two = subscriber.subscribe_to(bus_two)

      expect(subscriptions_from_one.method_names(event_name: :foo)).to eq([:foo])
      expect(subscriptions_from_two.method_names(event_name: :foo)).to eq([:foo])
    end

    it "raises when calling the same instance multiple times for the same bus" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :foo

        def foo; end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)

      expect {
        subscriber.subscribe_to(bus)
      }.to raise_error(described_class::MultipleSubscriberSubscriptionAttemptError)
    end
  end
end
