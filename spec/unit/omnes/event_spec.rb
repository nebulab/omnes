# frozen_string_literal: true

require "omnes/event"

RSpec.describe Omnes::Event do
  describe "#name" do
    it "returns a symbol" do
      Foo = Class.new(Omnes::Event)

      expect(Foo.new.name.is_a?(Symbol)).to be(true)
    ensure
      Object.send(:remove_const, :Foo)
    end

    it "returns class name downcased" do
      Foo = Class.new(Omnes::Event)

      expect(Foo.new.name).to be(:foo)
    ensure
      Object.send(:remove_const, :Foo)
    end

    it "replaces module separator with underscores" do
      module Foo
        Bar = Class.new(Omnes::Event)
      end

      expect(Foo::Bar.new.name).to be(:foo_bar)
    ensure
      Object.send(:remove_const, :Foo)
    end

    it "replaces all module separators with underscores" do
      module Foo
        module Bar
          Baz = Class.new(Omnes::Event)
        end
      end

      expect(Foo::Bar::Baz.new.name).to be(:foo_bar_baz)
    ensure
      Object.send(:remove_const, :Foo)
    end

    it "adds an underscore before a capitalized character preceded by a lowercase char" do
      FooBar = Class.new(Omnes::Event)

      expect(FooBar.new.name).to be(:foo_bar)
    ensure
      Object.send(:remove_const, :FooBar)
    end

    it "adds an underscore before a capitalized character preceded by an uppercase char" do
      FBar = Class.new(Omnes::Event)

      expect(FBar.new.name).to be(:f_bar)
    ensure
      Object.send(:remove_const, :FBar)
    end

    it "removes an Event suffix if present" do
      FooEvent = Class.new(Omnes::Event)

      expect(FooEvent.new.name).to be(:foo)
    ensure
      Object.send(:remove_const, :FooEvent)
    end
  end
end
