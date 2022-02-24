# frozen_string_literal: true

require 'spec_helper'
require 'omnes/subscriber/subscriptions'
require 'omnes/subscription'

RSpec.describe Omnes::Subscriber::Subscriptions do
  let(:subscription_class) { Omnes::Subscription }

  describe 'method_names' do
    it "returns subscribers' method names for given event" do
      context = Class.new do
        def method_one; end
        def method_two; end
        def method_three; end
      end.new
      subscriptions = described_class.new(
        subscriptions: [
          subscription_class.new(pattern: :foo, block: context.method(:method_one)),
          subscription_class.new(pattern: :foo, block: context.method(:method_two)),
          subscription_class.new(pattern: :bar, block: context.method(:method_three))
        ]
      )

      expect(subscriptions.method_names(event_name: :foo)).to match_array(%i[method_one method_two])
    end
  end

  describe 'event_names' do
    it "returns subscribers' event names for given method name" do
      context = Class.new do
        def method_one; end
        def method_two; end
      end.new
      subscriptions = described_class.new(
        subscriptions: [
          subscription_class.new(pattern: :foo, block: context.method(:method_one)),
          subscription_class.new(pattern: :bar, block: context.method(:method_one)),
          subscription_class.new(pattern: :foo, block: context.method(:method_two))
        ]
      )

      expect(subscriptions.event_names(method_name: :method_one)).to match_array(%i[foo bar])
    end
  end
end
