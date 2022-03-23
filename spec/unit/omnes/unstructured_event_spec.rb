# frozen_string_literal: true

require "spec_helper"

RSpec.describe Omnes::UnstructuredEvent do
  describe "#[]" do
    it "accesses payload" do
      event = described_class.new(payload: { foo: :bar }, omnes_event_name: :foo)

      expect(event[:foo]).to be(:bar)
    end
  end
end
