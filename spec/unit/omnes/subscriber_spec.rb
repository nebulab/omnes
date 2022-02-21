# frozen_string_literal: true

require 'spec_helper'
require 'omnes/subscriber'

RSpec.describe Omnes::Subscriber do
  describe '#call' do
    it 'returns an execution instance' do
      subscriber = described_class.new(pattern: 'foo', block: proc {})

      expect(subscriber.call(:event)).to be_a(Omnes::Execution)
    end

    it "binds the event and sets execution's result" do
      subscriber = described_class.new(pattern: 'foo', block: ->(event) { event[:foo] })

      execution = subscriber.call(foo: :bar)

      expect(execution.result).to eq(:bar)
    end

    it 'sets itself as the execution subscriber' do
      subscriber = described_class.new(pattern: 'foo', block: proc { 'foo' })

      execution = subscriber.call(:event)

      expect(execution.subscriber).to be(subscriber)
    end

    it "sets the execution's benchmark" do
      subscriber = described_class.new(pattern: 'foo', block: proc { 'foo' })

      execution = subscriber.call(:event)

      expect(execution.benchmark).to be_a(Benchmark::Tms)
    end
  end

  describe '#matches?' do
    it 'return true when given event name matches pattern as a string' do
      subscriber = described_class.new(pattern: 'foo', block: -> {})

      expect(subscriber.matches?('foo')).to be(true)
    end

    it 'return true when given event name matches pattern as a regexp' do
      subscriber = described_class.new(pattern: /oo/, block: -> {})

      expect(subscriber.matches?('foo')).to be(true)
    end

    it "returns false when given event name doesn't match pattern" do
      subscriber = described_class.new(pattern: 'foo', block: -> {})

      expect(subscriber.matches?('bar')).to be(false)
    end

    it "returns false when given event name matches but the subscriber is unsubscribed from the event" do
      subscriber = described_class.new(pattern: 'foo', block: -> {})

      subscriber.unsubscribe('foo')

      expect(subscriber.matches?('foo')).to be(false)
    end
  end

  describe '#unsubscribe' do
    context 'when event name matches' do
      it "adds an exclusion so that it no longer matches" do
        subscriber = described_class.new(pattern: 'foo', block: -> {})

        expect(subscriber.matches?('foo')).to be(true)

        subscriber.unsubscribe('foo')

        expect(subscriber.matches?('foo')).to be(false)
      end
    end

    context "when event name doesn't match" do
      it 'does nothing' do
        subscriber = described_class.new(pattern: 'foo', block: -> {})

        subscriber.unsubscribe('bar')

        expect(subscriber.matches?('foo')).to be(true)
        expect(subscriber.matches?('bar')).to be(false)
      end
    end
  end

  describe '#subscribers' do
    it 'returns a list containing only itself' do
      subscriber = described_class.new(pattern: 'foo', block: -> {})

      expect(subscriber.subscribers).to eq([subscriber])
    end
  end
end
