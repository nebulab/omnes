# frozen_string_literal: true

require "spec_helper"
require "omnes"
require "support/shared_examples/bus"

RSpec.describe Omnes do
  subject { Class.new.include(described_class) }

  include_examples "bus"
end
