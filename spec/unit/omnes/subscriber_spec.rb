# frozen_string_literal: true

require 'spec_helper'
require 'omnes/subscriber'

RSpec.describe Omnes::Subscriber do
  describe '#call' do
    it 'returns an execution instance' do
      subscriber = described_class.new(pattern: :foo, block: proc {})

      expect(subscriber.call(:event)).to be_a(Omnes::Execution)
    end

    it "binds the event and sets execution's result" do
      subscriber = described_class.new(pattern: :foo, block: ->(event) { event[:foo] })

      execution = subscriber.call(foo: :bar)

      expect(execution.result).to eq(:bar)
    end

    it 'sets itself as the execution subscriber' do
      subscriber = described_class.new(pattern: :foo, block: proc { 'foo' })

      execution = subscriber.call(:event)

      expect(execution.subscriber).to be(subscriber)
    end

    it "sets the execution's benchmark" do
      subscriber = described_class.new(pattern: :foo, block: proc { 'foo' })

      execution = subscriber.call(:event)

      expect(execution.benchmark).to be_a(Benchmark::Tms)
    end
  end

  describe '#matches?' do
    it 'return true when given event name is equal to the pattern' do
      subscriber = described_class.new(pattern: :foo, block: -> {})

      expect(subscriber.matches?(:foo)).to be(true)
    end

    it 'return true when given event name matches pattern as a regexp' do
      subscriber = described_class.new(pattern: /oo/, block: -> {})

      expect(subscriber.matches?(:foo)).to be(true)
    end

    it "returns false when given event name doesn't match pattern" do
      subscriber = described_class.new(pattern: :foo, block: -> {})

      expect(subscriber.matches?(:bar)).to be(false)
    end

    it "return false when given event name partially match the pattern" do
      subscriber = described_class.new(pattern: :foo, block: -> {})

      expect(subscriber.matches?(:oo)).to be(false)
    end

    it "return false when pattern partially matches given event name" do
      subscriber = described_class.new(pattern: :oo, block: -> {})

      expect(subscriber.matches?(:foo)).to be(false)
    end

    it 'returns false when given event name matches but the subscriber is unsubscribed from the event' do
      subscriber = described_class.new(pattern: /foo/, block: -> {})

      subscriber.exclude(:foo)

      expect(subscriber.matches?(:foo)).to be(false)
    end
  end

  describe '#exclude' do
    it 'adds an exclusion so that it no longer matches' do
      subscriber = described_class.new(pattern: /foo/, block: -> {})

      expect(subscriber.matches?(:foo)).to be(true)

      subscriber.exclude(:foo)

      expect(subscriber.matches?(:foo)).to be(false)
    end
  end

  describe '#subscribers' do
    it 'returns a list containing only itself' do
      subscriber = described_class.new(pattern: :foo, block: -> {})

      expect(subscriber.subscribers).to eq([subscriber])
    end
  end

  describe '#regexp?' do
    context 'when pattern is a Regexp' do
      it 'returns true' do
        subscriber = described_class.new(pattern: /foo/, block: -> {})

        expect(subscriber.regexp?).to be(true)
      end
    end

    context 'when pattern is not a Regexp' do
      it 'returns false' do
        subscriber = described_class.new(pattern: :foo, block: -> {})

        expect(subscriber.regexp?).to be(false)
      end
    end
  end
end
