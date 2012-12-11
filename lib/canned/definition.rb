require "canned/errors"
require "canned/stack"
require "canned/profile"
require "canned/profile_dsl"
require "canned/context/default"


module Canned

  ## Definition module
  #
  # This module is used to generate a canned definition that can later
  # be refered when calling "canned_setup".
  #
  # TODO: Usage
  #
  module Definition

    def self.included(klass)
      klass.class_eval("
        @@tests = {}
        @@profiles = {}

        def self.tests; @@tests end
        def self.profiles; @@profiles end
      ", __FILE__, __LINE__ + 1)
      klass.extend ClassMethods
    end

    module ClassMethods

      ## Defines a new test that can be used in "certifies" instructions
      #
      # **IMPORTANT** Tests are executed in the same context as upon blocks,
      #
      # @param [Symbol] _name test identifier
      # @param [Block] _block test block, arity must be 0
      #
      def test(_name, &_block)
        raise SetupError.new "Duplicated test identifier" if tests.has_key? _name
      end

      ## Creates a new profile and evaluates the given block using the profile context.
      #
      # @param [String|Symbol] _name Profile name.
      # @param [Hash] _options Various options: none for now
      #
      def profile(_name, _options={}, &_block)
        _name = _name.to_sym
        raise Canned::SetupError.new "Duplicated profile identifier '#{_name}'" if profiles.has_key? _name

        profile = Canned::Profile.new
        ProfileDsl.new(profile, profiles).instance_eval &_block
        profiles[_name] = profile
      end

      ## Returns true if **_action** is avaliable for **_profile** under the given **_ctx**.
      #
      # @param [Canned2::TestContext] _ctx The test context to be used
      # @param [string] _acting_as The name of profile to be tested
      # @param [String] _action The action to test
      #
      def validate(_ctx, _acting_as, _action)
        profile = profiles[_acting_as.to_sym]
        raise Canned::SetupError.new "Profile not found '#{_acting_as}'" if profile.nil?
        _ctx = Canned::Context::Default.new(_ctx, tests, InmmutableStack.new)
        profile.validate _ctx, _action
      end
    end
  end
end