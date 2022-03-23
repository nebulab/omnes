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

  describe ".config.event" do
    it "returns Omnes::Event.config" do
      expect(
        described_class.config.event
      ).to be(Omnes::Event.config)
    end
  end

  describe ".config.subscriber" do
    it "returns Omnes::Subscriber.config" do
      expect(
        described_class.config.subscriber
      ).to be(Omnes::Subscriber.config)
    end
  end

  describe ".config.subscriber.adapter.sidekiq" do
    it "returns Omnes::Subscriber::Adapter::Sidekiq.config" do
      expect(
        described_class.config.subscriber.adapter.sidekiq
      ).to be(Omnes::Subscriber::Adapter::Sidekiq.config)
    end
  end

  describe ".config.subscriber.adapter.active_job" do
    it "returns Omnes::Subscriber::Adapter::ActiveJob.config" do
      expect(
        described_class.config.subscriber.adapter.active_job
      ).to be(Omnes::Subscriber::Adapter::ActiveJob.config)
    end
  end
end
