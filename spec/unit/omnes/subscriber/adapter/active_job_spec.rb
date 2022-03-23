# frozen_string_literal: true

require "spec_helper"
require "active_job"
require "active_job/test_helper"
require "omnes/bus"
require "omnes/subscriber"

RSpec.describe Omnes::Subscriber::Adapter::ActiveJob do
  include ActiveJob::TestHelper

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

  it "can specify how to serialize the event" do
    class Subscriber < ActiveJob::Base
      include Omnes::Subscriber

      EVENT_SERIALIZER = lambda do |event|
        {
          "id" => event.id,
          "attributes" => {
            "name" => event.attributes[:name]
          }
        }
      end

      handle :create_foo, with: Adapter::ActiveJob[serializer: EVENT_SERIALIZER]

      def perform(payload)
        FOO_TABLE[payload["id"]] = payload["attributes"]
      end
    end
    event = Struct.new(:name, :id, :attributes).new(:create_foo, 1, { name: "foo" })
    FOO_TABLE = {}

    bus.register(:create_foo)
    Subscriber.new.subscribe_to(bus)

    bus.publish(event)
    perform_enqueued_jobs

    expect(FOO_TABLE[1]).to eq("name" => "foo")
  ensure
    Object.send(:remove_const, :Subscriber)
    Object.send(:remove_const, :FOO_TABLE)
  end
end
