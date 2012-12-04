module Canned

  ## The test context
  #
  # The test context provides all operations avaliable inside **upon** blocks, including access
  # to loaded resources and controller.
  #
  # It also mantains an "actor stack", this allows the context to provide upon blocks inside upon blocks
  # where different actors can be queried in its own context.
  #
  # Some examples of usage inside upon blocks:
  #
  #     # Matching an actor property with a request param:
  #     allow upon(:user) { asks_for_same(:role_name) }
  #     # ... short hand for...
  #     allow upon(:user) { asks_for(:role_name, equal_to: role_name) }
  #
  #     # Matching an actor property with a request param if param is an id:
  #     allow upon(:user) { asks_for_same_id(:app_id) }
  #
  #     # Matching actions
  #     allow upon(:user) { needs_to(:create, :update) }
  #
  #     # Testing a relation between actor and a preloaded resource
  #     allow upon(:user) { belongs_to(:account) }
  #
  #     # Mixing everything
  #     # - Will only allow user if searches by name and belongs to requested account and is an admin
  #     allow upon(:user) { asks_for(:search, equal_to: 'by_name') and belongs_to(:account) and is_admin? }
  #
  class TestContext

    def initialize(_provider)
      @_provider = _provider
      @_actor_stack = []
    end

    ## Redirect "self" to actor.
    def self
      actor
    end

    ## Gets the context actor
    def actor
      raise SetupError.new "Must provide an actor usign upon(<actor_name>)" if @_actor_stack.empty?
      @_actor_stack.last
    end

    ## Gets the context controller (provider)
    def controller
      @_provider
    end

    ## Changes the actor context for the upcoming block
    def upon(_name=nil, &_block)
      upon_with_ctx(_name, self, &_block)
    end

    ## Same as upon but allows specifying the context
    def upon_with_ctx(_name, _ctx, &_block)
      if _name.nil?
        return _ctx.instance_eval &_block
      else
        raise SetupError.new "Actor not found '#{_name}'" unless @_provider.actors.has_key? _name
        @_actor_stack.push @_provider.actors[_name]
        result = _ctx.instance_eval &_block
        @_actor_stack.pop
        return result
      end
    end

    ## Tests if the request action name is between **_actions**
    def needs_to(*_actions)
      _actions.any? { |a| a.to_s == @_provider.action_name }
    end

    ## Tests if a given param is **equal_to** or **equal_to_id** or **greater_than** or **less_than** a given value.
    def asks_for(_param, _opt={})
      return false unless @_provider.params.has_key? _param
      value = @_provider.params[_param]

      if _opt.has_key? :equal_to
        return false unless value == _opt[:equal_to]
      end

      if _opt.has_key? :equal_to_id
        return false unless value.respond_to? :to_i
        return false unless _opt[:equal_to_id] == :wildcard or value.to_i == _opt[:equal_to_id]
      end

      if _opt.has_key? :greater_than
        return false unless value.respond_to? :to_f
        return false unless _opt[:greater_than] == :wildcard or value.to_f > _opt[:greater_than]
      end

      if _opt.has_key? :less_than
        return false unless value.respond_to? :to_f
        return false unless _opt[:less_than] == :wildcard or value.to_f < _opt[:less_than]
      end

      return true
    end

    ## Tests if a set of request param values are the same as corresponding actor's properties
    def asks_for_same(*_params)
      # TODO: support hash actor
      _params.all? { |p| asks_for(p, equal_to: actor.send(p)) }
    end

    ## Tests if a set of request param values are the same as corresponding actor's properties, does a integer comparison
    def asks_for_same_id(*_params)
      # TODO: support hash actor
      _params.all? { |p| asks_for(p, equal_to_id: actor.send(p)) }
    end

    ## Test if current actor belongs to **_model**
    def belongs_to(_model, _options={})
      as = _options[:as]
      as = _model.class.name.parameterize if as.nil?

      if _model.respond_to? :reflect_on_association
        assoc = actor.reflect_on_association(as)
        raise CannedSetupError.new 'Invalid association name' if assoc.nil?
        raise CannedSetupError.new 'Thorugh assoc is not supported' if assoc.options.has_key? :through # TODO: support through!
        raise CannedSetupError.new 'Invalid association type' if assoc.macro != :belongs_to
        actor.send(assoc.foreign_key) == _model.id
      else
        _model.send(:id) == actor.send("#{as}_id")
      end
    end

    ## Test if **_model** belongs to current actor
    def has(_model, _options={})
      as = _options[:as]
      as = actor.class.name.parameterize if as.nil?

      if _model.respond_to? :reflect_on_association
        assoc = _model.reflect_on_association(as)
        raise CannedSetupError.new 'Invalid association name' if assoc.nil?
        raise CannedSetupError.new 'Thorugh assoc is not supported' if assoc.options.has_key? :through # TODO: support through!
        raise CannedSetupError.new 'Invalid association type' if assoc.macro != :belongs_to
        _model.send(assoc.foreign_key) == actor.id
      else
        _model.send("#{as}_id") == actor.send(:id)
      end
    end

    ## Resolve missing calls first by seeking resoures and then sending them to the underlying actor
    def method_missing(_method, *_args, &_block)
      return @_provider.resources[_method] if _args.count == 0 and _block.nil? and @_provider.resources.has_key? _method
      return @_actor_stack.last.send(_method, *_args, &_block) unless @_actor_stack.empty?
      super
    end
  end
end