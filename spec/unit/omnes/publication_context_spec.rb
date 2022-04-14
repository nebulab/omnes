# frozen_string_literal: true

require "spec_helper"
require "omnes/publication_context"

RSpec.describe Omnes::PublicationContext do
  describe ".serialized" do
    it "serializes caller_location as string" do
      context = described_class.new(caller_location: caller_locations(0)[0], time: Time.now)

      expect(context.serialized["caller_location"]).to include(__FILE__)
    end

    it "serializes time as string" do
      context = described_class.new(caller_location: caller_locations(0)[0], time: Time.new(2022, 10, 10))

      expect(context.serialized["time"]).to include("2022-10-10")
    end
  end
end
