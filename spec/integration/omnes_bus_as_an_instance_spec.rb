# frozen_string_literal: true

require 'omnes/bus'

RSpec.describe 'Omnes bus as an instance' do
  it 'can be used as a standalone instance' do
    klass = Class.new do
      attr_reader :bus, :dependency

      def initialize(dependency:)
        @bus = Omnes::Bus.new
        bus.register(:foo)
        @collaborator = dependency
      end

      def call
        bus.publish(:foo)
      end
    end
    collaborator = Struct.new(:called).new(false)
    instance = klass.new(dependency: collaborator)
    instance.bus.subscribe(:foo) do
      collaborator.called = true
    end

    instance.call

    expect(collaborator.called).to be(true)
  end
end
