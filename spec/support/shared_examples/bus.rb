# frozen_string_literal: true

RSpec.shared_examples 'bus' do
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

  describe '#register' do
    it 'adds the event to the register' do
      bus = subject.new

      bus.register(:foo)

      expect(bus.registry.registered?(:foo)).to be(true)
    end

    it 'raises when the event is already in the registry' do
      bus = subject.new
      bus.register(:foo, caller_location: caller_locations(0)[0])

      expect {
        bus.register(:foo)
      }.to raise_error(Omnes::AlreadyRegisteredEventError, /already registered.*#{__FILE__}/m)
    end
  end

  describe '#publish' do
    it 'executes direct subscriptions for given event name' do
      bus = subject.new
      dummy = counter.new
      bus.register(:foo)
      bus.subscribe(:foo) { dummy.inc }

      bus.publish :foo

      expect(dummy.count).to be(1)
    end

    it 'executes plain subscriptions for given event name' do
      bus = subject.new
      dummy = counter.new
      bus.register(:foo)
      bus.subscribe(:foo) { dummy.inc }

      bus.publish :foo

      expect(dummy.count).to be(1)
    end

    it 'executes regexp subscriptions for given event name' do
      bus = subject.new
      dummy = counter.new
      bus.register(:foo)
      bus.subscribe(/oo/) { dummy.inc }

      bus.publish :foo

      expect(dummy.count).to be(1)
    end

    it "doesn't execute other event subscriptions" do
      bus = subject.new
      dummy = counter.new
      bus.register(:bar)
      bus.subscribe(:bar) { dummy.inc }
      bus.register(:foo)

      bus.publish :foo

      expect(dummy.count).to be(0)
    end

    it "doesn't execute subscriptions partially matching" do
      bus = subject.new
      dummy = counter.new
      bus.register(:bar)
      bus.subscribe(:bar) { dummy.inc }
      bus.register(:barr)

      bus.publish :barr

      expect(dummy.count).to be(0)
    end

    it "doesn't execute subscriptions where the event partially matches" do
      bus = subject.new
      dummy = counter.new
      bus.register(:barr)
      bus.subscribe(:barr) { dummy.inc }
      bus.register(:bar)

      bus.publish :bar

      expect(dummy.count).to be(0)
    end

    it 'yields the given options to the subscription as the event payload' do
      bus = subject.new
      dummy = Class.new do
        attr_accessor :box
      end.new
      bus.register(:foo)
      bus.subscribe(:foo) { |event| dummy.box = event.payload[:box] }

      bus.publish :foo, box: 'foo'

      expect(dummy.box).to eq('foo')
    end

    it 'adds the published event with given caller location to the firing result object' do
      bus = subject.new
      bus.register(:foo)
      bus.subscribe(:foo) { :work }

      firing = bus.publish :foo, caller_location: caller_locations(0)[0]

      expect(firing.event.caller_location.to_s).to include(__FILE__)
    end

    it 'adds the triggered executions to the firing result object', :aggregate_failures do
      bus = subject.new
      dummy = counter.new
      bus.register(:foo)
      subscription1 = bus.subscribe(:foo) { dummy.inc }
      subscription2 = bus.subscribe(:foo) { dummy.inc }

      firing = bus.publish :foo

      executions = firing.executions
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

  describe '#subscribe' do
    it 'can subscribe as a block' do
      bus = subject.new
      bus.register(:foo)

      bus.subscribe(:foo) { :foo }

      subscription = bus.subscriptions.first
      expect(subscription.block.call).to be(:foo)
    end

    it 'can subscribe as anything callable' do
      bus = subject.new
      bus.register(:foo)
      callable = proc { :foo }


      bus.subscribe(:foo, callable)

      subscription = bus.subscriptions.first
      expect(subscription.block.call).to be(:foo)
    end

    it 'callable takes precedence over block' do
      bus = subject.new
      bus.register(:foo)
      callable = proc { :foo }

      bus.subscribe(:foo, callable) { :bar }

      subscription = bus.subscriptions.first
      expect(subscription.block.call).to be(:foo)
    end

    it 'registers to matching event', :aggregate_failures do
      bus = subject.new
      bus.register(:foo)

      block = -> {}
      bus.subscribe(:foo, &block)

      subscription = bus.subscriptions.first
      expect(subscription.pattern).to be(:foo)
      expect(subscription.block.object_id).to eq(block.object_id)
    end

    it 'registers to matching event as a regexp', :aggregate_failures do
      bus = subject.new
      bus.register(:foo)

      block = -> {}
      pattern = /oo/
      bus.subscribe(pattern, &block)

      subscription = bus.subscriptions.first
      expect(subscription.pattern).to be(pattern)
      expect(subscription.block.object_id).to eq(block.object_id)
    end

    it "raises when given event name hasn't been registered" do
      bus = subject.new

      expect {
        bus.subscribe(:foo)
      }.to raise_error(Omnes::UnknownEventError, /not registered/)
    end
  end

  describe '#unsubscribe' do
    it 'removes given subscription' do
      bus = subject.new
      dummy = counter.new
      bus.register(:foo)
      subscription = bus.subscribe(:foo) { dummy.inc }

      bus.unsubscribe subscription
      bus.publish :foo

      expect(dummy.count).to be(0)
    end
  end

  describe '#unregister' do
    it 'removes the event from the registry' do
      bus = subject.new
      bus.register(:foo)

      bus.unregister(:foo)

      expect(bus.registry.registered?(:foo)).to be(false)
    end

    it 'removes subscriptions for that event' do
      bus = subject.new
      bus.register(:foo)
      subscription = bus.subscribe(:foo)

      bus.unregister(:foo)

      expect(bus.subscriptions).not_to include(subscription)
    end

    it "doesn't remove subscriptions for other events" do
      bus = subject.new
      bus.register(:foo)
      bus.register(:bar)
      subscription = bus.subscribe(:foo)

      bus.unregister(:bar)

      expect(bus.subscriptions).to include(subscription)
    end

    it 'excludes events for regexp subscriptions that match the event' do
      bus = subject.new
      bus.register(:foo)
      subscription = bus.subscribe(/foo/)

      expect(subscription.matches?(:foo)).to be(true)

      bus.unregister(:foo)

      expect(subscription.matches?(:foo)).to be(false)
    end

    it "doesn't exclude the subscription to partial matches on the event" do
      bus = subject.new
      bus.register(:foo)
      bus.register(:fooo)
      subscription = bus.subscribe(/foo/)

      expect(subscription.matches?(:foo)).to be(true)
      expect(subscription.matches?(:fooo)).to be(true)

      bus.unregister(:foo)

      expect(subscription.matches?(:foo)).to be(false)
      expect(subscription.matches?(:fooo)).to be(true)
    end

    it "raises when given event name hasn't been registered" do
      bus = subject.new

      expect {
        bus.unregister(:foo)
      }.to raise_error(Omnes::UnknownEventError, /not registered/)
    end

    it "doesn't exclude regexp subscriptions when the event hasn't been registered" do
      bus = subject.new

      subscription = bus.subscribe(/foo/)

      expect { bus.unregister(:foo) }.to raise_error(Omnes::UnknownEventError, /not registered/)

      expect(subscription.matches?(:foo)).to be(true)
    end
  end

  describe '#with_subscriptions' do
    it 'returns a new instance with given subscriptions', :aggregate_failures do
      bus = subject.new
      dummy1, dummy2, dummy3 = Array.new(3) { counter.new }
      bus.register(:foo)
      subscription1 = bus.subscribe(:foo) { dummy1.inc }
      subscription2 = bus.subscribe(:foo) { dummy2.inc }
      subscription3 = bus.subscribe(:foo) { dummy3.inc }

      new_bus = bus.with_subscriptions([subscription1, subscription2])
      new_bus.publish(:foo)

      expect(new_bus).not_to eq(bus)
      expect(new_bus.subscriptions).to match_array([subscription1, subscription2])
      expect(dummy1.count).to be(1)
      expect(dummy2.count).to be(1)
      expect(dummy3.count).to be(0)
    end

    it 'keeps the same registry' do
      bus = subject.new
      bus.register(:foo)

      new_bus = bus.with_subscriptions([])

      expect(new_bus.registry).to be(bus.registry)
    end
  end
end
