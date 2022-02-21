# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Omnes::Event do
  describe '#[]' do
    it 'accesses payload' do
      event = described_class.new(payload: { foo: :bar }, caller_location: :here)

      expect(event[:foo]).to be(:bar)
    end
  end
end
