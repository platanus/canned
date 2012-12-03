module Canned
  ## Upon block context.
  # allows '' do
  #   upon(:user_data) { matches(:site_id, using: :equals_int) or matches(:section_id) and passes(:is_owner) }
  #   upon { matches('current_user.site_id', with: :site_id) or matches(:section_id) }
  #   upon(:user) { matches(:site_id) or matches(:section_id) and passes(:test) or holds('user.is_active?') }
  #   upon { holds('@raffle.id == current_user.id') }
  # end
  class TestContext

    def initialize(_provider)
      @_provider = _provider
      @_actor_stack = []
    end

    ## Redirect "self" to actor.
    def self
      actor
    end

    def actor
      raise SetupError.new "Must provide an actor usign upon(<actor_name>)" if @_actor_stack.empty?
      @_actor_stack.last
    end

    ## Gets the
    def controller
      @_provider
    end

    ## Resolve missing calls first by seeking resoures and then sending them to the underlying actor
    def method_missing(_method, *_args, &_block)
      return @_provider.resources[_method] if _args.count == 0 and _block.nil? and @_provider.resources.has_key? _method
      return @_actor_stack.last.send(_method, *_args, &_block) unless @_actor_stack.empty?
      super
    end

    def upon(_name=nil, &_block)
      upon_with_ctx(_name, self, &_block)
    end

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

    ##
    def calls(*_actions)
      _actions.any? { |a| a.to_s == @_provider.action_name }
    end

    ## Test whether
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

    def asks_for_same(*_params)
      # TODO: support hash actor
      _params.all? { |p| asks_for(p, equal_to: actor.send(p)) }
    end

    def asks_for_same_id(*_params)
      # TODO: support hash actor
      _params.all? { |p| asks_for(p, equal_to_id: actor.send(p)) }
    end

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
  end
end