# frozen_string_literal: true

require "spec_helper"
require "omnes/subscriber/subscriptions"
require "omnes/subscription"

RSpec.describe Omnes::Subscriber::Subscriptions do
  let(:subscription_class) { Omnes::Subscription }

  describe "#method_names" do
    it "returns subscribers' method names for given event" do
      context = Class.new do
        def method_one; end
        def method_two; end
        def method_three; end
      end.new
      subscriptions = described_class.new(
        subscriptions: [
          subscription_class.new(event_name: :foo, callback: context.method(:method_one)),
          subscription_class.new(event_name: :foo, callback: context.method(:method_two)),
          subscription_class.new(event_name: :bar, callback: context.method(:method_three))
        ]
      )

      expect(subscriptions.method_names(event_name: :foo)).to match_array(%i[method_one method_two])
    end
  end

  describe "#event_names" do
    it "returns subscribers' event names for given method name" do
      context = Class.new do
        def method_one; end
        def method_two; end
      end.new
      subscriptions = described_class.new(
        subscriptions: [
          subscription_class.new(event_name: :foo, callback: context.method(:method_one)),
          subscription_class.new(event_name: :bar, callback: context.method(:method_one)),
          subscription_class.new(event_name: :foo, callback: context.method(:method_two))
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
      subscription = subscription_class.new(event_name: :foo, callback: context.method(:method_one))
      subscriptions = described_class.new(
        subscriptions: [subscription]
      )

      expect(subscriptions.subscriptions).to eq([subscription])
    end

    it "returns subscriptions matching given event name" do
      context = Class.new do
        def method_one; end
      end.new
      subscription_foo = subscription_class.new(event_name: :foo, callback: context.method(:method_one))
      subscription_bar = subscription_class.new(event_name: :bar, callback: context.method(:method_one))
      subscriptions = described_class.new(
        subscriptions: [subscription_foo, subscription_bar]
      )

      expect(subscriptions.subscriptions(event_name: :foo)).to eq([subscription_foo])
    end

    it "returns subscriptions matching given method name" do
      context = Class.new do
        def method_one; end
        def method_two; end
      end.new
      subscription_one = subscription_class.new(event_name: :foo, callback: context.method(:method_one))
      subscription_two = subscription_class.new(event_name: :foo, callback: context.method(:method_two))
      subscriptions = described_class.new(
        subscriptions: [subscription_one, subscription_two]
      )

      expect(subscriptions.subscriptions(method_name: :method_one)).to eq([subscription_one])
    end

    it "returns subscriptions matching given event and method names" do
      context = Class.new do
        def method_one; end
        def method_two; end
      end.new
      subscription_foo_one = subscription_class.new(event_name: :foo, callback: context.method(:method_one))
      subscription_foo_two = subscription_class.new(event_name: :foo, callback: context.method(:method_two))
      subscription_bar_one = subscription_class.new(event_name: :bar, callback: context.method(:method_one))
      subscriptions = described_class.new(
        subscriptions: [subscription_foo_one, subscription_foo_two, subscription_bar_one]
      )

      expect(
        subscriptions.subscriptions(event_name: :foo, method_name: :method_one)
      ).to eq([subscription_foo_one])
    end
  end
end
