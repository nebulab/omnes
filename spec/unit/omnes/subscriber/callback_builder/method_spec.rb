# frozen_string_literal: true

require "spec_helper"
require "omnes/subscriber/callback_builder/method"

RSpec.describe Omnes::Subscriber::CallbackBuilder::Method do
  describe "#call" do
    it "returns lambda that calls method with given event" do
      instance = Class.new do
        def foo(event)
          event
        end
      end.new

      callback = described_class.new(:foo).(instance)

      expect(callback.(:bar)).to be(:bar)
    end

    it "raises when method is private" do
      instance = Class.new do
        private def foo; end
      end.new

      expect {
        described_class.new(:foo).(instance)
      }.to raise_error(
        described_class::PrivateMethodSubscriptionAttemptError,
        /"foo" private method/m
      )
    end

    it "raises when method doesn't exist" do
      instance = Class.new.new

      expect {
        described_class.new(:foo).(instance)
      }.to raise_error(
        described_class::UnknownMethodSubscriptionAttemptError,
        /"foo" method/m
      )
    end
  end
end
