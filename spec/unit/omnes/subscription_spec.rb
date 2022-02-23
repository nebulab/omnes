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

    it 'return true when given event name matches pattern as a regexp' do
      subscription = described_class.new(pattern: /oo/, block: -> {})

      expect(subscription.matches?(:foo)).to be(true)
    end

    it "returns false when given event name doesn't match pattern" do
      subscription = described_class.new(pattern: :foo, block: -> {})

      expect(subscription.matches?(:bar)).to be(false)
    end

    it "return false when given event name partially match the pattern" do
      subscription = described_class.new(pattern: :foo, block: -> {})

      expect(subscription.matches?(:oo)).to be(false)
    end

    it "return false when pattern partially matches given event name" do
      subscription = described_class.new(pattern: :oo, block: -> {})

      expect(subscription.matches?(:foo)).to be(false)
    end

    it 'returns false when given event name matches but the subscription is removed from the event' do
      subscription = described_class.new(pattern: /foo/, block: -> {})

      subscription.exclude(:foo)

      expect(subscription.matches?(:foo)).to be(false)
    end
  end

  describe '#exclude' do
    it 'adds an exclusion so that it no longer matches' do
      subscription = described_class.new(pattern: /foo/, block: -> {})

      expect(subscription.matches?(:foo)).to be(true)

      subscription.exclude(:foo)

      expect(subscription.matches?(:foo)).to be(false)
    end
  end

  describe '#subscriptions' do
    it 'returns a list containing only itself' do
      subscription = described_class.new(pattern: :foo, block: -> {})

      expect(subscription.subscriptions).to eq([subscription])
    end
  end

  describe '#regexp?' do
    context 'when pattern is a Regexp' do
      it 'returns true' do
        subscription = described_class.new(pattern: /foo/, block: -> {})

        expect(subscription.regexp?).to be(true)
      end
    end

    context 'when pattern is not a Regexp' do
      it 'returns false' do
        subscription = described_class.new(pattern: :foo, block: -> {})

        expect(subscription.regexp?).to be(false)
      end
    end
  end
end
