# frozen_string_literal: true

require "spec_helper"
require "omnes/bus"
require "omnes/subscriber"
require "sidekiq/testing"

RSpec.describe Omnes::Subscriber::Adapter::Sidekiq do
  before do
    Sidekiq.strict_args!
    Sidekiq::Testing.inline!
  end

  let(:bus) { Omnes::Bus.new }

  it "performs the job async passing the event's payload" do
    class Subscriber
      include Omnes::Subscriber
      include Sidekiq::Job

      handle :create_foo, with: Adapter::Sidekiq

      def perform(payload)
        FOO_TABLE[payload["id"]] = payload["attributes"]
      end
    end
    FOO_TABLE = {}

    bus.register(:create_foo)
    Subscriber.new.subscribe_to(bus)

    bus.publish(:create_foo, "id" => 1, "attributes" => { "name" => "foo" })

    expect(FOO_TABLE[1]).to eq("name" => "foo")
  ensure
    Object.send(:remove_const, :Subscriber)
    Object.send(:remove_const, :FOO_TABLE)
  end

  it "can specify how to serialize the event" do
    class Subscriber
      include Omnes::Subscriber
      include Sidekiq::Job

      EVENT_SERIALIZER = lambda do |event|
        {
          "id" => event.id,
          "attributes" => {
            "name" => event.attributes[:name]
          }
        }
      end

      handle :create_foo, with: Adapter::Sidekiq[serializer: EVENT_SERIALIZER]

      def perform(payload)
        FOO_TABLE[payload["id"]] = payload["attributes"]
      end
    end
    event = Struct.new(:name, :id, :attributes).new(:create_foo, 1, { name: "foo" })
    FOO_TABLE = {}

    bus.register(:create_foo)
    Subscriber.new.subscribe_to(bus)

    bus.publish(event)

    expect(FOO_TABLE[1]).to eq("name" => "foo")
  ensure
    Object.send(:remove_const, :Subscriber)
    Object.send(:remove_const, :FOO_TABLE)
  end

  it "performs the job in given interval after the publication passing the event's payload" do
    class Subscriber
      include Sidekiq::Job
      include Omnes::Subscriber

      handle :create_foo, with: Adapter::Sidekiq.in(60)

      def perform(payload)
        FOO_TABLE[payload["id"]] = payload["attributes"]
      end
    end
    FOO_TABLE = {}

    bus.register(:create_foo)
    Subscriber.new.subscribe_to(bus)

    expect(Subscriber).to receive(:perform_in).with(60, any_args).and_call_original

    bus.publish(:create_foo, "id" => 1, "attributes" => { "name" => "foo" })

    expect(FOO_TABLE[1]).to eq("name" => "foo")
  ensure
    Object.send(:remove_const, :FOO_TABLE)
    Object.send(:remove_const, :Subscriber)
  end
end
