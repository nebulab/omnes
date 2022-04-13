# frozen_string_literal: true

require "omnes/configurable"

RSpec.describe Omnes::Configurable do
  subject { Class.new.extend(described_class) }

  describe ".config" do
    it "returns configuration class" do
      expect(subject.config.is_a?(described_class::Config)).to be(true)
    end
  end

  describe ".configure" do
    it "yields the configuration instance" do
      subject.configure do |config|
        expect(config).to be(subject.config)
      end
    end
  end

  describe ".setting" do
    it "sets default as the setting value" do
      subject.setting :foo, default: :bar

      expect(subject.config.settings[:foo]).to be(:bar)
    end

    it "creates a reader for the setting in config" do
      subject.setting :foo, default: :bar

      expect(subject.config.foo).to be(:bar)
    end

    it "creates a writter for the setting in config" do
      subject.setting :foo, default: :bar

      subject.config.foo = :baz

      expect(subject.config.foo).to be(:baz)
    end
  end

  describe ".nest_config" do
    it "adds a reader in config to access another constant config" do
      other = Class.new.extend(described_class)

      subject.nest_config other, name: :other

      expect(subject.config.other).to be(other.config)
    end

    it "defaults reader name to the downcased class name" do
      Other = Class.new.extend(described_class)

      subject.nest_config Other

      expect(subject.config.other).to be(Other.config)
    ensure
      Object.send(:remove_const, :Other)
    end

    it "adds an underscore before a capitalized character preceded by a lowercase char in the default name" do
      OtherClass = Class.new.extend(described_class)

      subject.nest_config OtherClass

      expect(subject.config.other_class).to be(OtherClass.config)
    ensure
      Object.send(:remove_const, :OtherClass)
    end

    it "only takes the last hierarchy level for the default name" do
      module Top
        Bottom = Class.new.extend(Omnes::Configurable)
      end

      subject.nest_config Top::Bottom

      expect(subject.config.bottom).to be(Top::Bottom.config)
    ensure
      Object.send(:remove_const, :Top)
    end
  end
end
