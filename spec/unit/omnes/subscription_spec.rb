# frozen_string_literal: true

require "spec_helper"
require "omnes/subscription"

RSpec.describe Omnes::Subscription do
  describe "#call" do
    it "returns an execution instance" do
      subscription = described_class.new(event_name: :foo, callback: proc {})

      expect(subscription.call(:event)).to be_a(Omnes::Execution)
    end

    it "binds the event and sets execution's result" do
      subscription = described_class.new(event_name: :foo, callback: ->(event) { event[:foo] })

      execution = subscription.call(foo: :bar)

      expect(execution.result).to eq(:bar)
    end

    it "sets itself as the execution subscription" do
      subscription = described_class.new(event_name: :foo, callback: proc { "foo" })

      execution = subscription.call(:event)

      expect(execution.subscription).to be(subscription)
    end

    it "sets the execution's benchmark" do
      subscription = described_class.new(event_name: :foo, callback: proc { "foo" })

      execution = subscription.call(:event)

      expect(execution.benchmark).to be_a(Benchmark::Tms)
    end
  end

  describe "#matches?" do
    it "return true when given candidate is equal to the event_name" do
      subscription = described_class.new(event_name: :foo, callback: -> {})

      expect(subscription.matches?(:foo)).to be(true)
    end

    it "returns false when given candidate doesn't match event_name" do
      subscription = described_class.new(event_name: :foo, callback: -> {})

      expect(subscription.matches?(:bar)).to be(false)
    end
  end

  describe "#subscriptions" do
    it "returns a list containing only itself" do
      subscription = described_class.new(event_name: :foo, callback: -> {})

      expect(subscription.subscriptions).to eq([subscription])
    end
  end
end
