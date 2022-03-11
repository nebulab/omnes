# frozen_string_literal: true

require "omnes/bus"
require "omnes/subscriber"

RSpec.describe Omnes::Subscriber do
  let(:subscriber_class) do
    Class.new do
      include Omnes::Subscriber

      attr_reader :called

      def initialize
        @called = false
      end
    end
  end
  let(:bus) { Omnes::Bus.new }

  it "autodiscovers and subscribes methods matching registered events" do
    bus.register(:foo)
    subscriber_class.class_eval do
      def on_foo(_event)
        @called = true
      end
    end
    subscriber = subscriber_class.new

    subscriber.subscribe_to(bus)
    bus.publish(:foo)

    expect(subscriber.called).to be(true)
  end

  describe ".[]" do
    it "can specify custom strategy to autodiscover" do
      bus.register(:foo)
      subscriber_class = Class.new do
        include Omnes::Subscriber[autodiscover_strategy: ->(event_name) { :"left_#{event_name}_right" }]

        attr_reader :called

        def inititalize
          @called = false
        end

        def left_foo_right(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    end

    it "can switch off autodiscovery" do
      bus.register(:foo)
      subscriber_class = Class.new do
        include Omnes::Subscriber[autodiscover_strategy: nil]

        def on_foo(_event)
          __method__
        end
      end

      subscriber_class.new.subscribe_to(bus)

      expect(bus.subscriptions.empty?).to be(true)
    end
  end

  describe ".handle" do
    it "subscribes to the event matching given name" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :foo

        def foo(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    end

    it "doesn't subscribe to other events" do
      bus.register(:foo)
      bus.register(:bar)
      subscriber_class.class_eval do
        handle :foo, with: :foo

        def foo(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:bar)

      expect(subscriber.called).to be(false)
    end

    it "builds the callback from a matching method when given a symbol" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :foo

        def foo(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    end

    it "builds the callback from given lambda" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: ->(instance, event) { instance.method(:bar).(event) }

        def bar(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    end

    it "raises when trying to subscribe to an unregistered event" do
      subscriber_class.class_eval do
        handle :foo, with: :foo

        def foo(_event); end
      end

      expect {
        subscriber_class.new.subscribe_to(bus)
      }.to raise_error(
        Omnes::UnknownEventError
      )
    end
  end

  describe ".handle_all" do
    it "subscribes to all events" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle_all with: :foo

        def foo(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    end

    it "builds the callback from a matching method when given a symbol" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle_all with: :foo

        def foo(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    end

    it "builds the callback from given lambda" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle_all with: ->(instance, event) { instance.method(:bar).(event) }

        def bar(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    end
  end

  describe ".handle_with_matcher" do
    it "subscribes to events matching with given matcher" do
      bus.register(:foo)
      subscriber_class.class_eval do
        TRUE_MATCHER = ->(_candidate) { true }

        handle_with_matcher TRUE_MATCHER, with: :foo

        def foo(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    end

    it "builds the callback from a matching method when given a symbol" do
      bus.register(:foo)
      subscriber_class.class_eval do
        TRUE_MATCHER = ->(_candidate) { true }

        handle_with_matcher TRUE_MATCHER, with: :foo

        def foo(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    end

    it "builds the callback from given lambda" do
      bus.register(:foo)
      subscriber_class.class_eval do
        TRUE_MATCHER = ->(_candidate) { true }

        handle_with_matcher TRUE_MATCHER, with: ->(instance, event) { instance.method(:bar).(event) }

        def bar(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    end
  end

  describe "#subscribe_to" do
    it "can subscribe multiple instances to the same bus" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :foo

        def foo(_event)
          @called = true
        end
      end
      subscriber1 = subscriber_class.new
      subscriber2 = subscriber_class.new

      subscriber1.subscribe_to(bus)
      subscriber2.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber1.called).to be(true)
      expect(subscriber2.called).to be(true)
    end

    it "can subscribe the same instance to different buses" do
      bus_one = Omnes::Bus.new
      bus_two = Omnes::Bus.new
      [bus_one, bus_two].each { |bus| bus.register(:foo) }
      subscriber_class.class_eval do
        handle :foo, with: :foo

        def foo(_event); end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus_one)
      subscriber.subscribe_to(bus_two)

      expect(bus_one.subscriptions.count).to be(1)
      expect(bus_two.subscriptions.count).to be(1)
    end

    it "doesn't add any subscription if there's an error" do
      bus.register(:foo)
      bus.register(:bar)
      subscriber_class.class_eval do
        handle :foo, with: :foo
        handle :bar, with: :bar

        def foo(_event); end
      end

      expect {
        subscriber_class.new.subscribe_to(bus)
      }.to raise_error(described_class::CallbackBuilder::Method::UnknownMethodSubscriptionAttemptError)

      expect(bus.subscriptions.count).to be(0)
    end

    it "raises when calling the same instance multiple times for the same bus" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :foo

        def foo(_event); end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)

      expect {
        subscriber.subscribe_to(bus)
      }.to raise_error(described_class::MultipleSubscriberSubscriptionAttemptError)
    end

    it "accepts the callback builder as a two args callable" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: ->(instance, event) { instance.method(:bar).(event) }

        def bar(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    end

    it "accepts the callback builder as a one arg callable" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: ->(instance) { ->(event) { instance.method(:bar).(event) } }

        def bar(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    end
  end
end
