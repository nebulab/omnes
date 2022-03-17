# frozen_string_literal: true

require "spec_helper"
require "omnes"
require "support/shared_examples/bus"

RSpec.describe Omnes do
  subject { Class.new.include(described_class) }

  include_examples "bus"

  describe ".config.subscriber" do
    it "returns Omnes::Subscriber.config" do
      expect(
        described_class.config.subscriber
      ).to be(Omnes::Subscriber.config)
    end
  end

  describe ".config.event" do
    it "returns Omnes::Event.config" do
      expect(
        described_class.config.event
      ).to be(Omnes::Event.config)
    end
  end
end
