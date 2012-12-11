module Canned

  ## Holds all rules associated to a single user profile.
  #
  # This class describes the avaliable DSL when defining a new profile.
  # TODO: example
  #
  class ProfileDsl

    def initialize(_profile, _loaded_profiles)
      @profile = _profile
      @loaded_profiles = _loaded_profiles
    end

    ## Sets the default context for this profile block.
    def context(_proc=nil, &_block)
      @profile.context = _proc || _block
    end

    ## Adds an "allowance" rule
    #
    #    Examples:
    #       allow 'index'
    #       allow 'index', upon(:user) { that(:is_admin) }
    #       allow('index') { upon(:user).that(:is_admin) }
    #       allow
    #       allow upon(:user) { that(:is_admin) }
    #       allow { upon(:user).that(:is_admin) }
    #
    # @param [String|Proc] _action The action to authorize, if no action is given then rule apply to any action.
    # @param [Proc] _proc The test procedure, if not given, then action is always allowed.
    #
    def allow(_action=nil, _proc=nil)

      if _action.is_a? Proc
        _proc = _action
        _action = nil
      end

      @profile.rules << { type: :allow, action: _action, proc: _proc }
    end

    ## Adds a "forbidden" rule
    #
    # Works the same way as **allow** but if rule checks then user is forbidden to access
    # the resource regardles of presenting another profile that passes.
    #
    def forbid(_action=nil, _proc=nil)

      if _action.is_a? Proc
        _proc = _action
        _action = nil
      end

      @profile.rules << { type: :forbid, action: _action, proc: _proc }
    end

    ## Breaks from the current profile scope if condition is not match.
    #
    # When calling this function from within a scope, it will only break from scope.
    #
    #   Example:
    #     # The following rules will be tested against every user
    #     allow 'index', upon(:user) { that(:is_registered) }
    #     allow 'index', upon(:user) { that(:is_alien) }
    #     allow 'index', upon(:user) { that(:is_chewbaka) }
    #
    #     continue upon(:user) { that(:is_jedi) }
    #     # The following rules will only be tested against jedis
    #     allow 'index', upon(:user) { with(:force).greater_than(100) }
    #
    #
    def continue(_proc)
      @profile.rules << { type: :continue, proc: _proc }
    end

    ## Embedds a _profile inside another one.
    #
    def expand(_profile)
      profile = @loaded_profiles[_profile]
      raise SetupError.new "Profile not found '#{_profile}'" if profile.nil?
      @profile.rules << { type: :expand, profile: profile }
    end

    ## Allows defining a set of rules with common options.
    #
    #   Example:
    #     # The following group
    #     scope upon: :user
    #       # the following only breaks from current scope.
    #       continue upon { that(:is_jedi) }
    #       # the following will only forbid jedis that belong to death star (resource).
    #       forbid 'index', upon { belongs_to(:death_star) }
    #       allow 'index', upon(:user) { that(:has_pony_tail) }
    #     end
    #
    #     # the following rule will be tested against every user.
    #     allow 'index', upon(:user) { that(:is_registered) }
    #
    #
    def scope(&_block)
      child = Profile.new
      ProfileDsl.new(child, @loaded_profiles).instance_eval &_block
      @profile.rules << { type: :scope, profile: child }
    end

    ## SHORT HAND METHODS

    ## Same as calling when { the() ... }
    def upon(*_args, &_block)
      if _args.count == 0
        return _block
      elsif _block
        Proc.new { the(*_args).instance_eval &_block }
      else
        Proc.new { the(*_args) }
      end
    end

    # TODO: Implement following

    # def upon_one(_expr, &_block)
    #   Proc.new { upon_one(_expr, &_block) }
    # end

    # def upon_all(_expr, &_block)
    #   Proc.new { upon_all(_expr, &_block) }
    # end
  end
end