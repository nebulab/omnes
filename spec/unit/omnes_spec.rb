# frozen_string_literal: true

require "spec_helper"
require "omnes"
require "support/shared_examples/bus"

RSpec.describe Omnes do
  subject { Class.new.include(described_class) }

  include_examples "bus"

  it "doesn't share buses between instances" do
    klass = Class.new.include(described_class)

    expect(klass.new.omnes_bus).not_to be(klass.new.omnes_bus)
  end

  describe ".config" do
    it "nests Omnes::Event config under event" do
      expect(
        described_class.config.event
      ).to be(Omnes::Event.config)
    end

    it "nests Omnes::Subscriber config under subscriber" do
      expect(
        described_class.config.subscriber
      ).to be(Omnes::Subscriber.config)
    end
  end
end
