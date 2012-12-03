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
        raise SetupError.new "Invalid test arity for '#{_name}'" if _block.arity != 0
        raise SetupError.new "Duplicated test identifier" if tests.has_key? _name
      end

      ## Creates a new profile and evaluates the given block using the profile context.
      #
      # @param [String|Symbol] _name Profile name.
      # @param [Hash] _options Various options:
      #     * upon: The default profile actor.
      #
      def profile(_name, _options={}, &_block)
        _name = _name.to_sym
        raise SetupError.new "Duplicated profile identifier '#{_name}'" if profiles.has_key? _name

        profile = Profile.new _options[:upon]
        ProfileBuilder.new(profile, profiles).instance_eval &_block
        profiles[_name] = profile
      end

      ## Returns true if **_action** is avaliable for **_profile** under the given **_ctx**.
      #
      # @param [Canned2::TestContext] _ctx The test context to be used
      # @param [string] _profile The name of profile to be tested
      # @param [String] _action The action to test
      #
      def validate(_ctx, _profile, _action)
        profile = profiles[_profile.to_sym]
        raise SetupError.new "Profile not found '#{_profile}'" if profile.nil?
        # TODO: avoid context wrapper
        profile.validate ContextWrapper.new(_ctx, tests), _action
      end
    end

  private

    class Profile

      attr_accessor :actor
      attr_accessor :rules

      def initialize(_actor)
        @actor = _actor
        @rules = []
      end

      def validate(_ctx, _action)

        _ctx.upon_with_ctx(@actor, self) do
          @rules.each do |rule|
            case rule[:type]
            when :allow
              if rule[:action].nil? or rule[:action] == _action
                return :allowed if rule[:upon].nil? or _ctx.instance_eval &rule[:upon]
              end
            when :forbid
              if rule[:action].nil? or rule[:action] == _action
                return :forbidden if rule[:upon].nil? or _ctx.instance_eval &rule[:upon]
              end
            when :continue
              # continue block's interrupt flow if false
              return :break unless _ctx.instance_eval &rule[:upon]
            when :call
              # when evaluating an cross profile call, any special
              # condition will cause to break.
              result = rule[:profile].validate(_ctx, _action)
              return result if result != :default
            when :child
              # when evaluating a child block, only break if a
              # matching allow or forbid is found.
              result = rule[:profile].validate(_ctx, _action)
              return result if result != :default and result != :break
            end
          end
        end

        # No rule matched, return not allowed.
        return :default
      end
    end

    ## Holds all rules associated to a single user profile.
    #
    # This class describes the avaliable DSL when defining a new profile.
    # TODO: example
    class ProfileBuilder

      def initialize(_profile, _loaded_profiles)
        @profile = _profile
        @loaded_profiles = _loaded_profiles
      end

      ## Adds an "allowance" rule
      def allow(_action=nil, _upon=nil)
        @profile.rules << { type: :allow, action: _action, upon: (_upon || _action) }
      end

      ## Adds a "forbidden" rule
      def forbid(_action=nil, _upon=nil)
        @profile.rules << { type: :forbid, action: _action, upon: _upon }
      end

      def carry_on(_upon)
        @profile.rules << { type: :continue, upon: _upon }
      end

      def call(_profile)
        profile = @loaded_profiles[_profile]
        raise SetupError.new "Profile not found '#{_profile}'" if profile.nil?
        @profile.rules << { type: :call, profile: profile }
      end

      def group(_options={}, &_block)
        child = Profile.new _options[:upon]
        ProfileBuilder.new(child, @loaded_profiles).instance_eval &_block
        @profile.rules << { type: :child, profile: child }
      end

      ## SHORT HAND METHODS

      def upon(_expr=nil, &_block)
        # TODO: replace wrapper proc by structure
        Proc.new { upon(_expr, &_block) }
      end

      # TODO: Implement following

      # def upon_one(_expr, &_block)
      #   Proc.new { upon_one(_expr, &_block) }
      # end

      # def upon_all(_expr, &_block)
      #   Proc.new { upon_all(_expr, &_block) }
      # end
    end

    ## Aggregates the test context with the "happens" method.
    #
    class ContextWrapper
      def initialize(_ctx, _tests)
        @ctx = _ctx
        @tests = _tests
      end

      ## Executes ones of the definition's global test using the wrapped context.
      def happens(_test)
        test = @tests[_test]
        raise SetupError.new "Invalid test name #{_test.to_s}" if test.nil?
        self.instance_exec &test # tests are evaluated in test context.
      end

      ## Send message to wrapped context if not recognized.
      def method_missing(_method, *_args, &_block)
        @ctx.send(_method, *_args, &_block)
      end
    end
  end
end