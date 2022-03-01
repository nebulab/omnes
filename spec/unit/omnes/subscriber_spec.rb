# frozen_string_literal: true

require 'omnes/bus'
require 'omnes/subscriber'

RSpec.describe Omnes::Subscriber do
  let(:subscriber_class) { Class.new.include(described_class) }
  let(:bus) { Omnes::Bus.new }

  describe '#subscribe_to' do
    it 'autodiscovers and subscribes methods matching registered events' do
      bus.register(:foo)
      subscriber_class.class_eval do
        def on_foo(_event)
          __method__
        end
      end

      subscriber_class.new.subscribe_to(bus)

      subscription = bus.subscriptions[0]
      expect(subscription.pattern).to be(:foo)
      expect(subscription.block.call(:event)).to be(:on_foo)
    end

    it 'subscribes with manually specified handlers' do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :bar

        def bar(_event)
          __method__
        end
      end

      subscriber_class.new.subscribe_to(bus)

      subscription = bus.subscriptions[0]
      expect(subscription.pattern).to be(:foo)
      expect(subscription.block.call(:event)).to be(:bar)
    end

    it 'raises when trying to subscribe to an autodiscovered private method' do
      bus.register(:foo)
      subscriber_class.class_eval do
        private def on_foo; end
      end

      expect {
        subscriber_class.new.subscribe_to(bus)
      }.to raise_error(
        described_class::PrivateMethodSubscriptionAttemptError,
        /event "foo".*"on_foo" private method/m
      )
    end

    it 'raises when trying to subscribe to a private method with manual definition' do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :bar

        private def bar; end
      end

      expect {
        subscriber_class.new.subscribe_to(bus)
      }.to raise_error(
        described_class::PrivateMethodSubscriptionAttemptError,
        /event "foo".*"bar" private method/m
      )
    end

    it 'returns a Subscriptions instance' do
      bus.register(:foo)
      subscriber_class.class_eval do
        def on_foo; end
      end

      subscriptions = subscriber_class.new.subscribe_to(bus)

      expect(subscriptions).to be_a(described_class::Subscriptions)
    end

    it 'can subscribe different methods to the same event with manual definition' do
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

    it 'can subscribe different methods to the same event mixing autodescovering and manual definition' do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :bar

        def on_foo; end
        def bar; end
      end

      subscriptions = subscriber_class.new.subscribe_to(bus)

      expect(subscriptions.method_names(event_name: :foo)).to match_array(%i[on_foo bar])
    end

    it 'can subscribe the same method to different events with manual definition' do
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

    it 'can subscribe the same method to different events mixing autodescovering and manual definition' do
      bus.register(:foo)
      bus.register(:bar)
      subscriber_class.class_eval do
        handle :bar, with: :on_foo

        def on_foo; end
      end

      subscriptions = subscriber_class.new.subscribe_to(bus)

      expect(subscriptions.event_names(method_name: :on_foo)).to match_array(%i[foo bar])
    end

    it 'raises when trying to subscribe the same method twice to the same event with manual definition' do
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
        /foo \/ foo/m
      )
    end

    it 'raises when trying to subscribe the same method twice to the same event mixing autodescovering and manual definition' do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :on_foo

        def on_foo; end
      end

      expect {
        subscriber_class.new.subscribe_to(bus)
      }.to raise_error(
        described_class::DuplicateSubscriptionAttemptError,
        /foo \/ on_foo/m
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
        /event "foo".*"bar" method/m
      )
    end

    it 'raises when trying to subscribe to an unregistered event' do
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
      subscriber_class.class_eval do
        handle :foo, with: :foo
        handle :bar, with: :bar

        def foo; end
      end

      expect { subscriber_class.new.subscribe_to(bus) }.to raise_error(described_class::UnknownMethodSubscriptionAttemptError)

      expect(bus.subscriptions.count).to be(0)
    end

    it 'raises FrozenSubscriber error when calling multiple times' do
      bus.register(:foo)
      subscriber_class.class_eval do
        handle :foo, with: :foo

        def foo; end
      end

      subscriber_class.new.subscribe_to(bus)

      expect { subscriber_class.new.subscribe_to(bus) }.to raise_error(described_class::FrozenSubscriberError)
    end

    it "can't add more subscriptions once it's been called" do
      bus.register(:foo)
      bus.register(:bar)
      subscriber_class.class_eval do
        handle :foo, with: :foo

        def foo; end
      end

      subscriber_class.new.subscribe_to(bus)

      expect { subscriber_class.new.subscribe_to(bus) }.to raise_error(described_class::FrozenSubscriberError)

      expect(bus.subscriptions.count).to be(1)
    end
  end
end
