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
      }.to raise_error(/already registered.*#{__FILE__}/m)
    end
  end

  describe '#publish' do
    it 'executes plain subscribers for given event name' do
      bus = subject.new
      dummy = counter.new
      bus.register(:foo)
      bus.subscribe(:foo) { dummy.inc }

      bus.publish :foo

      expect(dummy.count).to be(1)
    end

    it 'executes plain subscribers for given event name' do
      bus = subject.new
      dummy = counter.new
      bus.register(:foo)
      bus.subscribe(:foo) { dummy.inc }

      bus.publish :foo

      expect(dummy.count).to be(1)
    end

    it 'executes regexp subscribers for given event name' do
      bus = subject.new
      dummy = counter.new
      bus.register(:foo)
      bus.subscribe(/oo/) { dummy.inc }

      bus.publish :foo

      expect(dummy.count).to be(1)
    end

    it "doesn't execute other event subscribers" do
      bus = subject.new
      dummy = counter.new
      bus.register(:bar)
      bus.subscribe(:bar) { dummy.inc }
      bus.register(:foo)

      bus.publish :foo

      expect(dummy.count).to be(0)
    end

    it "doesn't execute subscribers partially matching" do
      bus = subject.new
      dummy = counter.new
      bus.register(:bar)
      bus.subscribe(:bar) { dummy.inc }
      bus.register(:barr)

      bus.publish :barr

      expect(dummy.count).to be(0)
    end

    it "doesn't execute subscribers where the event partially matches" do
      bus = subject.new
      dummy = counter.new
      bus.register(:barr)
      bus.subscribe(:barr) { dummy.inc }
      bus.register(:bar)

      bus.publish :bar

      expect(dummy.count).to be(0)
    end

    it 'yields the given options to the subscriber as the event payload' do
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
      subscriber1 = bus.subscribe(:foo) { dummy.inc }
      subscriber2 = bus.subscribe(:foo) { dummy.inc }

      firing = bus.publish :foo

      executions = firing.executions
      expect(executions.count).to be(2)
      expect(executions.map(&:subscriber)).to match([subscriber1, subscriber2])
      expect(executions.map(&:result)).to match([1, 2])
    end

    it 'normalizes given event name' do
      bus = subject.new
      dummy = counter.new
      bus.register(:foo)
      bus.subscribe(:foo) { dummy.inc }

      bus.publish 'foo'

      expect(dummy.count).to be(1)
    end

    it "raises when the published event hasn't been registered" do
      bus = subject.new

      expect {
        bus.publish(:foo)
      }.to raise_error(/not registered/)
    end
  end

  describe '#subscribe' do
    it 'registers to matching event', :aggregate_failures do
      bus = subject.new
      bus.register(:foo)

      block = -> {}
      bus.subscribe(:foo, &block)

      subscriber = bus.subscribers.first
      expect(subscriber.pattern).to be(:foo)
      expect(subscriber.block.object_id).to eq(block.object_id)
    end

    it 'registers to matching event as a regexp', :aggregate_failures do
      bus = subject.new
      bus.register(:foo)

      block = -> {}
      pattern = /oo/
      bus.subscribe(pattern, &block)

      subscriber = bus.subscribers.first
      expect(subscriber.pattern).to be(pattern)
      expect(subscriber.block.object_id).to eq(block.object_id)
    end

    it "raises when given event name hasn't been registered" do
      bus = subject.new

      expect {
        bus.subscribe(:foo)
      }.to raise_error(/not registered/)
    end

    it 'normalizes given event name' do
      bus = subject.new
      bus.register(:foo)

      block = -> {}
      bus.subscribe('foo', &block)

      subscriber = bus.subscribers.first
      expect(subscriber.pattern).to be(:foo)
      expect(subscriber.block.object_id).to eq(block.object_id)
    end
  end

  describe '#unsubscribe' do
    context 'when given a subscriber' do
      it 'unsubscribes given subscriber' do
        bus = subject.new
        dummy = counter.new
        bus.register(:foo)
        subscriber = bus.subscribe(:foo) { dummy.inc }

        bus.unsubscribe subscriber
        bus.publish :foo

        expect(dummy.count).to be(0)
      end
    end

    context 'when given an event name' do
      it 'unsubscribes all subscribers for that event' do
        bus = subject.new
        dummy = counter.new
        bus.register(:foo)
        bus.subscribe(:foo) { dummy.inc }

        bus.unsubscribe :foo
        bus.publish :foo

        expect(dummy.count).to be(0)
      end

      it 'removes subscribers for that event' do
        bus = subject.new
        dummy = counter.new
        bus.register(:foo)
        subscriber = bus.subscribe(:foo) { dummy.inc }

        bus.unsubscribe :foo

        expect(bus.subscribers).not_to include(subscriber)
      end

      it "raises when given event name hasn't been registered" do
        bus = subject.new

        expect {
          bus.unsubscribe(:foo)
        }.to raise_error(/not registered/)
      end
    end

    it 'unsubscribes subscribers that match event with a regexp' do
      bus = subject.new
      dummy = counter.new
      bus.register(:foo)
      bus.subscribe(/foo/) { dummy.inc }
      bus.unsubscribe :foo

      bus.publish :foo

      expect(dummy.count).to be(0)
    end

    it "doesn't unsubscribe subscribers for other events" do
      bus = subject.new
      dummy = counter.new
      bus.register(:foo)
      bus.register(:bar)

      bus.subscribe(:foo) { dummy.inc }
      bus.unsubscribe :bar
      bus.publish :foo

      expect(dummy.count).to be(1)
    end

    it 'can resubscribe other subscribers to the same event', :aggregate_failures do
      bus = subject.new
      dummy1, dummy2 = Array.new(2) { counter.new }
      bus.register(:foo)

      bus.subscribe(:foo) { dummy1.inc }
      bus.unsubscribe :foo
      bus.subscribe(:foo) { dummy2.inc }
      bus.publish :foo

      expect(dummy1.count).to be(0)
      expect(dummy2.count).to be(1)
    end
  end

  describe '#with_subscribers' do
    it 'returns a new instance with given subscribers', :aggregate_failures do
      bus = subject.new
      dummy1, dummy2, dummy3 = Array.new(3) { counter.new }
      bus.register(:foo)
      subscriber1 = bus.subscribe(:foo) { dummy1.inc }
      subscriber2 = bus.subscribe(:foo) { dummy2.inc }
      subscriber3 = bus.subscribe(:foo) { dummy3.inc }

      new_bus = bus.with_subscribers([subscriber1, subscriber2])
      new_bus.publish(:foo)

      expect(new_bus).not_to eq(bus)
      expect(new_bus.subscribers).to match_array([subscriber1, subscriber2])
      expect(dummy1.count).to be(1)
      expect(dummy2.count).to be(1)
      expect(dummy3.count).to be(0)
    end

    it 'keeps the same registry' do
      bus = subject.new
      bus.register(:foo)

      new_bus = bus.with_subscribers([])

      expect(new_bus.registry).to be(bus.registry)
    end
  end
end
