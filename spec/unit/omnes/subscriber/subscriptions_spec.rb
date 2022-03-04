# frozen_string_literal: true

require "spec_helper"
require "omnes/bus"
require "omnes/subscription"
require "omnes/subscriber/subscriptions"

RSpec.describe Omnes::Subscriber::Subscriptions do
  let(:bus) { Omnes::Bus.new }
  let(:true_strategy) { ->(_candidate) { true } }
  let(:false_strategy) { ->(_candidate) { false } }
  let(:subscription_class) { Omnes::Subscription }

  describe "#method_names" do
    it "returns method names for the subscribers matching given event name" do
      context = Class.new do
        def method_one; end
        def method_two; end
        def method_three; end
      end.new
      bus.register(:foo)
      subscriptions = described_class.new(
        bus: bus,
        subscriptions: [
          subscription_class.new(strategy: true_strategy, callback: context.method(:method_one)),
          subscription_class.new(strategy: true_strategy, callback: context.method(:method_two)),
          subscription_class.new(strategy: false_strategy, callback: context.method(:method_three))
        ]
      )

      expect(subscriptions.method_names(event_name: :foo)).to match_array(%i[method_one method_two])
    end

    it "raises UnknownEventError if the event is not registered" do
      subscriptions = described_class.new(bus: bus, subscriptions: [])

      expect {
        subscriptions.method_names(event_name: :foo)
      }.to raise_error(Omnes::UnknownEventError)
    end
  end

  describe "#event_names" do
    it "returns event names for the subscribers with given method name as callback" do
      context = Class.new do
        def method_one; end
      end.new
      bus.register(:foo)
      bus.register(:bar)
      subscriptions = described_class.new(
        bus: bus,
        subscriptions: [
          subscription_class.new(strategy: true_strategy, callback: context.method(:method_one))
        ]
      )

      expect(subscriptions.event_names(method_name: :method_one)).to match_array(%i[foo bar])
    end
  end

  describe "#subscriptions" do
    it "returns all subscriptions" do
      context = Class.new do
        def method_one; end
      end.new
      bus.register(:foo)
      subscription = subscription_class.new(strategy: true_strategy, callback: context.method(:method_one))
      subscriptions = described_class.new(
        bus: bus,
        subscriptions: [subscription]
      )

      expect(subscriptions.subscriptions).to eq([subscription])
    end

    it "returns subscriptions matching given event name" do
      context = Class.new do
        def method_one; end
      end.new
      bus.register(:foo)
      subscription_matching = subscription_class.new(strategy: true_strategy, callback: context.method(:method_one))
      subscription_not_matching = subscription_class.new(strategy: false_strategy,
                                                         callback: context.method(:method_one))
      subscriptions = described_class.new(
        bus: bus,
        subscriptions: [subscription_matching, subscription_not_matching]
      )

      expect(subscriptions.subscriptions(event_name: :foo)).to eq([subscription_matching])
    end

    it "returns subscriptions which callback is given method name" do
      context = Class.new do
        def method_one; end
        def method_two; end
      end.new
      subscription_one = subscription_class.new(strategy: true_strategy, callback: context.method(:method_one))
      subscription_two = subscription_class.new(strategy: true_strategy, callback: context.method(:method_two))
      subscriptions = described_class.new(
        bus: bus,
        subscriptions: [subscription_one, subscription_two]
      )

      expect(subscriptions.subscriptions(method_name: :method_one)).to eq([subscription_one])
    end

    it "returns subscriptions matching given event and which callback is given method name" do
      context = Class.new do
        def method_one; end
        def method_two; end
      end.new
      bus.register(:foo)
      subscription_matching_one = subscription_class.new(strategy: true_strategy, callback: context.method(:method_one))
      subscription_not_matching_one = subscription_class.new(strategy: false_strategy,
                                                             callback: context.method(:method_one))
      subscription_matching_two = subscription_class.new(strategy: true_strategy, callback: context.method(:method_two))
      subscriptions = described_class.new(
        bus: bus,
        subscriptions: [subscription_matching_one, subscription_not_matching_one, subscription_matching_two]
      )

      expect(
        subscriptions.subscriptions(event_name: :foo, method_name: :method_one)
      ).to eq([subscription_matching_one])
    end
  end
end
