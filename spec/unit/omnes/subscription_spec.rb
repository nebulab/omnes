# frozen_string_literal: true

require 'spec_helper'
require 'omnes/subscription'

RSpec.describe Omnes::Subscription do
  describe '#call' do
    it 'returns an execution instance' do
      subscription = described_class.new(pattern: :foo, block: proc {})

      expect(subscription.call(:event)).to be_a(Omnes::Execution)
    end

    it "binds the event and sets execution's result" do
      subscription = described_class.new(pattern: :foo, block: ->(event) { event[:foo] })

      execution = subscription.call(foo: :bar)

      expect(execution.result).to eq(:bar)
    end

    it 'sets itself as the execution subscription' do
      subscription = described_class.new(pattern: :foo, block: proc { 'foo' })

      execution = subscription.call(:event)

      expect(execution.subscription).to be(subscription)
    end

    it "sets the execution's benchmark" do
      subscription = described_class.new(pattern: :foo, block: proc { 'foo' })

      execution = subscription.call(:event)

      expect(execution.benchmark).to be_a(Benchmark::Tms)
    end
  end

  describe '#matches?' do
    it 'return true when given event name is equal to the pattern' do
      subscription = described_class.new(pattern: :foo, block: -> {})

      expect(subscription.matches?(:foo)).to be(true)
    end

    it "returns false when given event name doesn't match pattern" do
      subscription = described_class.new(pattern: :foo, block: -> {})

      expect(subscription.matches?(:bar)).to be(false)
    end
  end

  describe '#subscriptions' do
    it 'returns a list containing only itself' do
      subscription = described_class.new(pattern: :foo, block: -> {})

      expect(subscription.subscriptions).to eq([subscription])
    end
  end
end
