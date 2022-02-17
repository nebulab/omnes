# frozen_string_literal: true

require 'spec_helper'
require 'omnes/bus'
require 'support/shared_examples/bus'

RSpec.describe Omnes::Bus do
  subject { described_class }

  include_examples 'bus'
end
