# frozen_string_literal: true

require "omnes/event"

RSpec.describe Omnes::Event do
  describe "#omnes_event_name" do
    it "returns a symbol" do
      Foo = Class.new.include(Omnes::Event)

      expect(Foo.new.omnes_event_name.is_a?(Symbol)).to be(true)
    ensure
      Object.send(:remove_const, :Foo)
    end

    it "returns class name downcased" do
      Foo = Class.new.include(Omnes::Event)

      expect(Foo.new.omnes_event_name).to be(:foo)
    ensure
      Object.send(:remove_const, :Foo)
    end

    it "replaces module separator with underscores" do
      module Foo
        Bar = Class.new.include(Omnes::Event)
      end

      expect(Foo::Bar.new.omnes_event_name).to be(:foo_bar)
    ensure
      Object.send(:remove_const, :Foo)
    end

    it "replaces all module separators with underscores" do
      module Foo
        module Bar
          Baz = Class.new.include(Omnes::Event)
        end
      end

      expect(Foo::Bar::Baz.new.omnes_event_name).to be(:foo_bar_baz)
    ensure
      Object.send(:remove_const, :Foo)
    end

    it "adds an underscore before a capitalized character preceded by a lowercase char" do
      FooBar = Class.new.include(Omnes::Event)

      expect(FooBar.new.omnes_event_name).to be(:foo_bar)
    ensure
      Object.send(:remove_const, :FooBar)
    end

    it "adds an underscore before a capitalized character preceded by an uppercase char" do
      FBar = Class.new.include(Omnes::Event)

      expect(FBar.new.omnes_event_name).to be(:f_bar)
    ensure
      Object.send(:remove_const, :FBar)
    end

    it "removes an Event suffix if present" do
      FooEvent = Class.new.include(Omnes::Event)

      expect(FooEvent.new.omnes_event_name).to be(:foo)
    ensure
      Object.send(:remove_const, :FooEvent)
    end
  end
end
