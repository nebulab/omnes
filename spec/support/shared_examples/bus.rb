# frozen_string_literal: true

RSpec.shared_examples "bus" do
  let(:counter) do
    Class.new do
      attr_reader :count

      def initialize
        @count = 0
      end

      def inc
        @count += 1
      end
    end
  end

  describe "#register" do
    it "adds the event name to the register" do
      bus = subject.new

      bus.register(:foo)

      expect(bus.registry.registered?(:foo)).to be(true)
    end

    it "provides caller location to the registration" do
      bus = subject.new

      bus.register(:foo)

      expect(bus.registry.registration(:foo).caller_location.to_s).to include(__FILE__)
    end

    it "raises when the event name is already registered" do
      bus = subject.new
      bus.register(:foo, caller_location: caller_locations(0)[0])

      expect {
        bus.register(:foo)
      }.to raise_error(Omnes::AlreadyRegisteredEventError, /already registered.*#{__FILE__}/m)
    end
  end

  describe "#publish" do
    it "executes subscriptions matching given event name" do
      bus = subject.new
      dummy = counter.new
      bus.register(:foo)
      bus.subscribe(:foo) { dummy.inc }

      bus.publish :foo

      expect(dummy.count).to be(1)
    end

    it "doesn't execute subscriptions that don't match" do
      bus = subject.new
      dummy = counter.new
      bus.register(:bar)
      bus.subscribe(:bar) { dummy.inc }
      bus.register(:foo)

      bus.publish :foo

      expect(dummy.count).to be(0)
    end

    it "can publish an unstructured event yielding given kwargs to the subscription as the event payload" do
      bus = subject.new
      dummy = Class.new do
        attr_accessor :box
      end.new
      bus.register(:foo)
      bus.subscribe(:foo) { |event| dummy.box = event.payload[:box] }

      bus.publish :foo, box: "foo"

      expect(dummy.box).to eq("foo")
    end

    it "can publish an event instance including Omnes::Event, yielding it to the subscription" do
      FooEvent = Class.new do
        include Omnes::Event

        def bar
          :bar
        end
      end
      dummy = Class.new do
        attr_accessor :box
      end.new
      bus = subject.new
      bus.register(:foo)
      bus.subscribe(:foo) { |event| dummy.box = event.bar }

      bus.publish FooEvent.new

      expect(dummy.box).to eq(:bar)
    ensure
      Object.send(:remove_const, :FooEvent)
    end

    it "can publish an event instance with an omnes_event_name method, yielding it to the subscription" do
      my_event = Class.new do
        def omnes_event_name
          :foo
        end

        def bar
          :bar
        end
      end
      dummy = Class.new do
        attr_accessor :box
      end.new
      bus = subject.new
      bus.register(:foo)
      bus.subscribe(:foo) { |event| dummy.box = event.bar }

      bus.publish my_event.new

      expect(dummy.box).to eq(:bar)
    end

    it "adds the caller location to the publication result object" do
      bus = subject.new
      bus.register(:foo)
      bus.subscribe(:foo) { :work }

      publication = bus.publish :foo

      expect(publication.caller_location.to_s).to include(__FILE__)
    end

    it "adds the publication time to the publication result object" do
      bus = subject.new
      bus.register(:foo)
      bus.subscribe(:foo) { :work }

      publication = bus.publish :foo

      expect(publication.publication_time).not_to be(nil)
    end

    it "adds the published event to the publication result object" do
      bus = subject.new
      bus.register(:foo)
      bus.subscribe(:foo) { :work }

      publication = bus.publish :foo

      expect(publication.event.is_a?(Omnes::UnstructuredEvent)).to be(true)
    end

    it "adds the triggered executions to the publication result object" do
      bus = subject.new
      dummy = counter.new
      bus.register(:foo)
      subscription1 = bus.subscribe(:foo) { dummy.inc }
      subscription2 = bus.subscribe(:foo) { dummy.inc }

      publication = bus.publish :foo

      executions = publication.executions
      expect(executions.count).to be(2)
      expect(executions.map(&:subscription)).to match([subscription1, subscription2])
      expect(executions.map(&:result)).to match([1, 2])
    end

    it "raises when the published event hasn't been registered" do
      bus = subject.new

      expect {
        bus.publish(:foo)
      }.to raise_error(Omnes::UnknownEventError, /not registered/)
    end
  end

  describe "#subscribe_with_matcher" do
    let(:true_matcher) { ->(_candidate) { true } }
    let(:false_matcher) { ->(_candidate) { false } }

    it "can subscribe as a block" do
      bus = subject.new
      bus.register(:foo)

      bus.subscribe_with_matcher(true_matcher) { :foo }

      subscription = bus.subscriptions.first
      expect(subscription.callback.()).to be(:foo)
    end

    it "can subscribe as anything callable" do
      bus = subject.new
      bus.register(:foo)
      callable = proc { :foo }

      bus.subscribe_with_matcher(true_matcher, callable)

      subscription = bus.subscriptions.first
      expect(subscription.callback.()).to be(:foo)
    end

    it "callable takes precedence over block" do
      bus = subject.new
      bus.register(:foo)
      callable = proc { :foo }

      bus.subscribe_with_matcher(true_matcher, callable) { :bar }

      subscription = bus.subscriptions.first
      expect(subscription.callback.()).to be(:foo)
    end

    it "runs when matcher returns true" do
      dummy = counter.new
      bus = subject.new
      bus.register(:foo)

      bus.subscribe_with_matcher(true_matcher) { dummy.inc }
      bus.publish(:foo)

      expect(dummy.count).to be(1)
    end

    it "doesn't run when matcher returns false" do
      dummy = counter.new
      bus = subject.new
      bus.register(:foo)

      bus.subscribe_with_matcher(false_matcher) { dummy.inc }
      bus.publish(:foo)

      expect(dummy.count).to be(0)
    end
  end

  describe "#subscribe" do
    it "can subscribe as a block" do
      bus = subject.new
      bus.register(:foo)

      bus.subscribe(:foo) { :foo }

      subscription = bus.subscriptions.first
      expect(subscription.callback.()).to be(:foo)
    end

    it "can subscribe as anything callable" do
      bus = subject.new
      bus.register(:foo)
      callable = proc { :foo }

      bus.subscribe(:foo, callable)

      subscription = bus.subscriptions.first
      expect(subscription.callback.()).to be(:foo)
    end

    it "callable takes precedence over block" do
      bus = subject.new
      bus.register(:foo)
      callable = proc { :foo }

      bus.subscribe(:foo, callable) { :bar }

      subscription = bus.subscriptions.first
      expect(subscription.callback.()).to be(:foo)
    end

    it "runs when published event matches" do
      dummy = counter.new
      bus = subject.new
      bus.register(:foo)

      bus.subscribe(:foo) { dummy.inc }
      bus.publish(:foo)

      expect(dummy.count).to be(1)
    end

    it "doesn't run when published event doesn't match" do
      dummy = counter.new
      bus = subject.new
      bus.register(:foo)
      bus.register(:bar)

      bus.subscribe(:foo) { dummy.inc }
      bus.publish(:bar)

      expect(dummy.count).to be(0)
    end

    it "raises when given event name hasn't been registered" do
      bus = subject.new

      expect {
        bus.subscribe(:foo)
      }.to raise_error(Omnes::UnknownEventError, /not registered/)
    end
  end

  describe "#subscribe_to_all" do
    it "can subscribe as a block" do
      bus = subject.new
      bus.register(:foo)

      bus.subscribe_to_all { :foo }

      subscription = bus.subscriptions.first
      expect(subscription.callback.()).to be(:foo)
    end

    it "can subscribe as anything callable" do
      bus = subject.new
      bus.register(:foo)
      callable = proc { :foo }

      bus.subscribe_to_all(callable)

      subscription = bus.subscriptions.first
      expect(subscription.callback.()).to be(:foo)
    end

    it "callable takes precedence over block" do
      bus = subject.new
      bus.register(:foo)
      callable = proc { :foo }

      bus.subscribe_to_all(callable) { :bar }

      subscription = bus.subscriptions.first
      expect(subscription.callback.()).to be(:foo)
    end

    it "runs for every event" do
      dummy = counter.new
      bus = subject.new
      bus.register(:foo)

      bus.subscribe_to_all { dummy.inc }
      bus.publish(:foo)

      expect(dummy.count).to be(1)
    end
  end

  describe "#unsubscribe" do
    it "removes given subscription" do
      bus = subject.new
      dummy = counter.new
      bus.register(:foo)
      subscription = bus.subscribe(:foo) { dummy.inc }

      bus.unsubscribe subscription
      bus.publish :foo

      expect(dummy.count).to be(0)
    end
  end

  describe "#with_subscriptions" do
    it "returns a new instance with given subscriptions" do
      bus = subject.new
      dummy1, dummy2, dummy3 = Array.new(3) { counter.new }
      bus.register(:foo)
      subscription1 = bus.subscribe(:foo) { dummy1.inc }
      subscription2 = bus.subscribe(:foo) { dummy2.inc }
      bus.subscribe(:foo) { dummy3.inc }

      new_bus = bus.with_subscriptions([subscription1, subscription2])
      new_bus.publish(:foo)

      expect(new_bus).not_to eq(bus)
      expect(new_bus.subscriptions).to match_array([subscription1, subscription2])
      expect(dummy1.count).to be(1)
      expect(dummy2.count).to be(1)
      expect(dummy3.count).to be(0)
    end

    it "keeps the same registry" do
      bus = subject.new
      bus.register(:foo)

      new_bus = bus.with_subscriptions([])

      expect(new_bus.registry).to be(bus.registry)
    end

    it "caller location start is 1" do
      bus = subject.new
      bus.register(:foo)

      new_bus = bus.with_subscriptions([])

      expect(new_bus.cal_loc_start).to be(1)
    end
  end
end
