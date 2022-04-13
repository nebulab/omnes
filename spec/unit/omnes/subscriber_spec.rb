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

  it "autodiscover is off by default" do
    bus.register(:foo)
    subscriber_class = Class.new do
      include Omnes::Subscriber

      def on_foo(_event)
        __method__
      end
    end

    subscriber_class.new.subscribe_to(bus)

    expect(bus.subscriptions.empty?).to be(true)
  end

  describe ".[]" do
    it "can switch on autodiscovery" do
      bus.register(:foo)
      subscriber_class = Class.new do
        include Omnes::Subscriber[autodiscover: true]

        attr_reader :called

        def on_foo(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    end

    it "can specify custom strategy to autodiscover" do
      bus.register(:foo)
      subscriber_class = Class.new do
        include Omnes::Subscriber[
          autodiscover: true,
          autodiscover_strategy: ->(event_name) { :"left_#{event_name}_right" }
        ]

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

    it "can provide id for the subscription" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :foo, id: :foo

        def foo(_event); end
      end
      subscriber = subscriber_class.new

      subscriptions = subscriber.subscribe_to(bus)

      expect(bus.subscription(:foo)).to be(subscriptions[0])
    end

    it "can provide instance-based id for the subscription" do
      bus.register(:foo)
      subscriber_class = Class.new do
        include Omnes::Subscriber

        attr_reader :id_suffix

        def initialize(id_suffix)
          @id_suffix = id_suffix
        end

        handle :foo, with: :foo, id: ->(instance) { :"foo_#{instance.id_suffix}" }

        def foo(_event); end
      end
      subscriber = subscriber_class.new(:one)

      subscriptions = subscriber.subscribe_to(bus)

      expect(bus.subscription(:foo_one)).to be(subscriptions[0])
    end

    it "raises when given subscription id has already been used" do
      bus.register(:foo)
      bus.register(:bar)
      subscriber_class.class_eval do
        handle :foo, with: :foo, id: :foo
        handle :bar, with: :foo, id: :foo

        def foo(_event); end
      end
      subscriber = subscriber_class.new

      expect {
        subscriber.subscribe_to(bus)
      }.to raise_error(Omnes::DuplicateSubscriptionIdError)
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

    it "can provide id for the subscription" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle_all with: :foo, id: :all

        def foo(_event); end
      end
      subscriber = subscriber_class.new

      subscriptions = subscriber.subscribe_to(bus)

      expect(bus.subscription(:all)).to be(subscriptions[0])
    end

    it "can provide instance-based id for the subscription" do
      subscriber_class = Class.new do
        include Omnes::Subscriber

        attr_reader :id_suffix

        def initialize(id_suffix)
          @id_suffix = id_suffix
        end

        handle_all with: :foo, id: ->(instance) { :"foo_#{instance.id_suffix}" }

        def foo(_event); end
      end
      subscriber = subscriber_class.new(:one)

      subscriptions = subscriber.subscribe_to(bus)

      expect(bus.subscription(:foo_one)).to be(subscriptions[0])
    end

    it "raises when given subscription id has already been used" do
      subscriber_class.class_eval do
        handle_all with: :foo, id: :foo
        handle_all with: :foo, id: :foo

        def foo(_event); end
      end
      subscriber = subscriber_class.new

      expect {
        subscriber.subscribe_to(bus)
      }.to raise_error(Omnes::DuplicateSubscriptionIdError)
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
        ::TRUE_MATCHER = ->(_candidate) { true }

        handle_with_matcher TRUE_MATCHER, with: :foo

        def foo(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    ensure
      Object.send(:remove_const, :TRUE_MATCHER)
    end

    it "can provide id for the subscription" do
      bus.register(:foo)
      subscriber_class.class_eval do
        ::TRUE_MATCHER = ->(_candidate) { true }

        handle_with_matcher TRUE_MATCHER, with: :foo, id: :foo

        def foo(_event); end
      end
      subscriber = subscriber_class.new

      subscriptions = subscriber.subscribe_to(bus)

      expect(bus.subscription(:foo)).to be(subscriptions[0])
    ensure
      Object.send(:remove_const, :TRUE_MATCHER)
    end

    it "can provide instance-based id for the subscription" do
      subscriber_class = Class.new do
        include Omnes::Subscriber

        ::TRUE_MATCHER = ->(_candidate) { true }

        attr_reader :id_suffix

        def initialize(id_suffix)
          @id_suffix = id_suffix
        end

        handle_with_matcher TRUE_MATCHER, with: :foo, id: ->(instance) { :"foo_#{instance.id_suffix}" }

        def foo(_event); end
      end
      subscriber = subscriber_class.new(:one)

      subscriptions = subscriber.subscribe_to(bus)

      expect(bus.subscription(:foo_one)).to be(subscriptions[0])
    ensure
      Object.send(:remove_const, :TRUE_MATCHER)
    end

    it "raises when given subscription id has already been used" do
      subscriber_class.class_eval do
        ::TRUE_MATCHER = ->(_candidate) { true }

        handle_with_matcher TRUE_MATCHER, with: :foo, id: :foo
        handle_with_matcher TRUE_MATCHER, with: :foo, id: :foo

        def foo(_event); end
      end
      subscriber = subscriber_class.new

      expect {
        subscriber.subscribe_to(bus)
      }.to raise_error(Omnes::DuplicateSubscriptionIdError)
    ensure
      Object.send(:remove_const, :TRUE_MATCHER)
    end

    it "builds the callback from a matching method when given a symbol" do
      bus.register(:foo)
      subscriber_class.class_eval do
        ::TRUE_MATCHER = ->(_candidate) { true }

        handle_with_matcher TRUE_MATCHER, with: :foo

        def foo(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    ensure
      Object.send(:remove_const, :TRUE_MATCHER)
    end

    it "builds the callback from given lambda" do
      bus.register(:foo)
      subscriber_class.class_eval do
        ::TRUE_MATCHER = ->(_candidate) { true }

        handle_with_matcher TRUE_MATCHER, with: ->(instance, event) { instance.method(:bar).(event) }

        def bar(_event)
          @called = true
        end
      end
      subscriber = subscriber_class.new

      subscriber.subscribe_to(bus)
      bus.publish(:foo)

      expect(subscriber.called).to be(true)
    ensure
      Object.send(:remove_const, :TRUE_MATCHER)
    end
  end

  describe "#subscribe_to" do
    it "can subscribe multiple instances to the same bus" do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :foo, id: ->(instance) { instance.object_id }

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

    it "can subscribe multiple instances to the same bus with autodiscovery" do
      bus.register(:foo)
      subscriber_class = Class.new do
        include Omnes::Subscriber[autodiscover: true]

        attr_reader :called

        def initialize
          @called = false
        end

        def on_foo(_event)
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
      }.to raise_error(described_class::Adapter::Method::UnknownMethodSubscriptionAttemptError)

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

    it "accepts the adapter as a two args callable" do
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

    it "accepts the adapter as a one arg callable" do
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
