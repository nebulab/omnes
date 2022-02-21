# frozen_string_literal: true

require 'omnes'

RSpec.describe 'Omnes included' do
  it 'can be used included' do
    klass = Class.new do
      include Omnes

      attr_reader :dependency

      def initialize(dependency:)
        register(:foo)
        @collaborator = dependency
      end

      def call
        publish(:foo)
      end
    end
    collaborator = Struct.new(:called).new(false)
    instance = klass.new(dependency: collaborator)
    instance.subscribe(:foo) do
      collaborator.called = true
    end

    instance.call

    expect(collaborator.called).to be(true)
  end
end
