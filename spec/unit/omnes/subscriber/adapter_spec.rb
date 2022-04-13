# frozen_string_literal: true

require "omnes/subscriber/adapter"

RSpec.describe Omnes::Subscriber::Adapter do
  describe ".config" do
    it "nests Sidekiq.config under sidekiq" do
      expect(
        described_class.config.sidekiq
      ).to be(Omnes::Subscriber::Adapter::Sidekiq.config)
    end

    it "nests ActiveJob.config under active_job" do
      expect(
        described_class.config.active_job
      ).to be(Omnes::Subscriber::Adapter::ActiveJob.config)
    end
  end
end
