module Canned

  ## Action Controller extension
  #
  # Include this in the the base application controller and use the acts_as_restricted method to seal it.
  #
  #   ApplicationController << ActionController:Base
  #     include Canned:ControllerExt
  #
  #     # Call canned setup method passing the desired profile definition object
  #     acts_as_restricted Profiles do
  #
  #       # Put authentication code here...
  #
  #       # Return profiles you wish to validate
  #       [:profile_1, :profile_2]
  #     end
  #
  #   end
  #
  module ControllerExt

    def self.included(klass)
      class << klass
        attr_accessor :_cn_actors
        attr_accessor :_cn_excluded
        attr_accessor :_cn_resources
      end

      # actors are shared between subclasses
      klass.cattr_accessor :_cn_actors
      klass._cn_actors = ActiveSupport::HashWithIndifferentAccess.new

      klass.extend ClassMethods
    end

    ## Performs access authorization for current action
    #
    # @param [Definition] _definition Profile definition
    # @param [Array<String>] _profiles Profiles to validate
    # @returns [Boolean] True if action access is authorized
    #
    def perform_access_authorization(_definition, _profiles)
      # preload resources, retrieve resource proxy
      proxy = perform_resource_loading

      # load test context and execute profile validation
      ctx = Canned::TestContext.new proxy
      result = _profiles.collect do |profile|
        test_a = _definition.validate ctx, profile, controller_name
        return false if test_a == :forbidden
        test_b = _definition.validate ctx, profile, "#{controller_name}##{action_name}" # TODO: keep this?
        return false if test_b == :forbidden
        test_a == :allowed or test_b == :allowed
      end
      return result.any?
    end

    ## Performs resource loading for current action
    #
    # @returns [ControllerProxy] used for resource loading
    #
    def perform_resource_loading
      proxy = ControllerProxy.new self
      proxy.preload_resources_for action_name
      return proxy
    end

    ## Returns true if the current action is protected.
    #
    def is_restricted?
      return true if self.class._cn_excluded.nil?
      return false if self.class._cn_excluded == :all
      return !(self.class._cn_excluded.include? action_name.to_sym)
    end

    module ClassMethods

      ## Setups the controller user profile definitions and profile provider block (or proc)
      #
      # The passed method or block must return a list of profiles to be validated
      # by the definition.
      #
      # TODO: default definition (canned config)
      #
      # @param [Definition] _definition Profile definition
      # @param [Symbol] _method Profile provider method name
      # @param [Block] _block Profile provider block
      #
      def acts_as_restricted(_definition, _method=nil, &_block)
        self.before_filter do
          if is_restricted?
            profiles = Array(if _method.nil? then instance_eval(&_block) else send(_method) end)
            raise Canned::AuthError.new 'No profiles avaliable' if profiles.empty?
            case perform_access_authorization(_definition, profiles)
            when :forbidden; raise Canned::ForbiddenError.new
            when :break; raise Canned::AuthError.new
            when :default; raise Canned::AuthError.new
            end
          else perform_resource_loading end
        end
      end

      ## Removes protection for all controller actions.
      def unrestricted_all
        self._cn_excluded = :all
      end

      ## Removes protection for the especified controller actions.
      #
      # @param [splat] _excluded List of actions to be excluded.
      #
      def unrestricted(*_excluded)
        self._cn_excluded ||= []
        self._cn_excluded.push(*(_excluded.collect &:to_sym))
      end

      ## Registers a canned actor
      #
      # @param [String] _name Actor's name and generator method name if no block is given.
      # @param [Hash] _options Options:
      #     * as: If given, this si used as actor's name and _name is only used for generator retrieval.
      # @param [Block] _block generator block, used instead of generator method if given.
      #
      def register_actor(_name, _options={}, &_block)
        self._cn_actors[_options.fetch(:as, _name)] = _block || _name
      end

      ## Registers a canned resource
      #
      # @param [String] _name Resource name
      # @param [String] _options Options:
      #     * using: Parameter used as key if not block is given.
      #     * only: If set, will only load the resource for the given actions.
      #     * except: If set, will not load the resource for any of the given actions.
      #     * from: TODO load_resource :raffle, from: :site
      #     * as: TODO: load_resource :raffle, from: :site, as: :draws
      # @param [Block] _block generator block, will be called to generate the resource if needed.
      #
      def register_resource(_name, _options={}, &_block)
        self._cn_resources ||= []
        self._cn_resources << {
          name: _name,
          only: unless _options[:only].nil? then Array(_options[:only]) else nil end,
          except: Array(_options[:except]),
          loader: _block || Proc.new { eval(_name.to_s.camelize).find params[_options.fetch(:using, :id)] }
        }
      end

      def register_default_resources
        # TODO: Load resources using convention and controller names.
      end
    end

  private

    ## ActionController - TestContext adapter
    class ControllerProxy

      attr_reader :resources
      attr_reader :actors

      def initialize(_controller)
        @controller = _controller
        @resources = ActiveSupport::HashWithIndifferentAccess.new
        # actors are provided throug a dynamic loader.
        @actors = ActorLoader.new _controller, _controller.class._cn_actors
      end

      ## Proxies messages to wrapped controller.
      def method_missing(_method, *_args, &_block)
        @controller.send(_method, *_args, &_block)
      end

      ## Loads resources required by _action
      def preload_resources_for(_action)
        _action = _action.to_sym
        Array(@controller.class._cn_resources).each do |res|
          next unless res[:only].nil? or res[:only].include? _action
          next unless res[:except].nil? or !res[:except].include? _action

          @resources[res[:name]] = resource = @controller.instance_eval &res[:loader]
          @controller.instance_variable_set "@#{res[:name]}", resource
        end
      end

    private

      ## Allows actors to be served on demand, provides a hash–like interface
      # to TestContext through ControllerProxy.actors method.
      class ActorLoader

        def initialize(_controller, _loaders)
          @controller = _controller
          @loaders = _loaders
          @actor_cache = {}
        end

        def [](_key)
          _key = _key.to_sym
          return @actor_cache[_key] if @actor_cache.has_key? _key

          loader = @loaders[_key]
          raise Canned::SetupError.new "Invalid actor loader value" if loader.nil?
          actor = if loader.is_a? String then @controller.send(loader) else @controller.instance_eval(&loader) end
          @actor_cache[_key] = actor
        end

        def has_key?(_key)
          @loaders.has_key? _key.to_sym
        end
      end
    end
  end
end