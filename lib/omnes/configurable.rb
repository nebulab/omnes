# frozen_string_literal: true

module Omnes
  # Ad-hoc configurable behavior for Omnes
  #
  # Example:
  #
  # ```
  # Omnes.configure do |config|
  #   config.event.name_builder = MY_NAME_BUILDER
  # end
  # ```
  #
  # or
  #
  # ```
  # Omnes::Event.config.name_builder = MY_NAME_BUILDER
  # ```
  module Configurable
    # Class where readers and writers are defined
    class Config
      # @api private
      attr_reader :settings

      # @api private
      def initialize
        @_mutex = Mutex.new
        @settings = {}
      end

      # @api private
      def add_setting(name, default)
        @_mutex.synchronize do
          @settings[name] = default
          define_setting_reader(name)
          define_setting_writter(name)
        end
      end

      # @api private
      def add_nesting(constant, name = default_nesting_name(constant))
        @_mutex.synchronize do
          define_nesting_reader(constant, name)
        end
      end

      private

      def define_setting_reader(name)
        define_singleton_method(name) { @settings[name] }
      end

      def define_setting_writter(name)
        define_singleton_method(:"#{name}=") do |value|
          @_mutex.synchronize do
            @settings[name] = value
          end
        end
      end

      def define_nesting_reader(constant, name)
        define_singleton_method(name) { constant.config }
      end
    end

    # @api private
    def self.extended(klass)
      klass.instance_variable_set(:@config, Config.new)
    end

    # Returns the configuration class
    #
    # Use this class to access readers and writers for the defined settings or
    # nested configurations
    #
    # @return [Configurable::Config]
    def config
      @config
    end

    # Yields the configuration class
    #
    # @see #config
    def configure
      yield @config
    end

    # @api private
    def setting(name, default:)
      config.add_setting(name, default)
    end

    # @api private
    def nest_config(constant, name: default_nesting_name(constant))
      config.add_nesting(constant, name)
    end

    private

    def default_nesting_name(constant)
      constant.name
              .split("::")
              .last
              .gsub(/([[:alpha:]])([[:upper:]])/, '\1_\2')
              .downcase
    end
  end
end
