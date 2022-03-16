# frozen_string_literal: true

require "spec_helper"
require "active_job"
require "active_job/test_helper"
require "omnes/bus"
require "omnes/subscriber"

RSpec.describe Omnes::Subscriber::Adapter::ActiveJob do
  include ActiveJob::TestHelper

  describe "#call" do
    it "calls `perform_later` class method with the event payload" do
      event = Struct.new(:payload).new("foo")
      instance = Class.new do
        def self.perform_later(event)
          "#{event} called"
        end
      end.new

      expect(described_class.(instance, event)).to eq("foo called")
    end
  end

  describe "Integration" do
    let(:bus) { Omnes::Bus.new }

    before do
      ActiveJob::Base.queue_adapter = :test
      ActiveJob::Base.logger = Logger.new(nil)
    end

    it "performs the job async passing the event's payload" do
      class Subscriber < ActiveJob::Base
        include Omnes::Subscriber

        handle :create_foo, with: Adapter::ActiveJob

        def perform(payload)
          FOO_TABLE[payload["id"]] = payload["attributes"]
        end
      end
      FOO_TABLE = {}

      bus.register(:create_foo)
      Subscriber.new.subscribe_to(bus)

      bus.publish(:create_foo, "id" => 1, "attributes" => { "name" => "foo" })
      perform_enqueued_jobs

      expect(FOO_TABLE[1]).to eq("name" => "foo")
    ensure
      Object.send(:remove_const, :Subscriber)
      Object.send(:remove_const, :FOO_TABLE)
    end
  end
end
