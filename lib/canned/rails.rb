module Canned

  ## Action Controller extension
  #
  # Include this in the the base application controller and use the canned_setup method to seal it.
  #
  #   ApplicationController << ActionController:Base
  #     include Canned:ControllerExt
  #
  #     # Call canned setup method passing the desired profile definition object
  #     can_with Profiles do
  #
  #       # Put authentication code here...
  #
  #       # Return profiles you wish to validate
  #       return [:profile_1, :profile_2]
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
      klass.extend ClassMethods
    end

    module ClassMethods

      ## Setups the controller user profile definitions and profile provider block (or proc)
      #
      # The passed method or block must return a list of profiles to be validated
      # by the definition.
      #
      # @param [Definition] _def Profile definition
      # @param [Symbol] _method Profile provider method name
      # @param [Block] _block Profile provider block
      #
      def can_with(_def, _method=nil, &_block)
        self.before_filter do
          klass = self.class

          # no auth if action is excluded
          next if klass._cn_excluded == :all
          next if !klass._cn_excluded.nil? and klass._cn_excluded.include? action_name.to_sym

          # call initializer block and extract profiles
          profiles = Array(if _method.nil? then instance_eval(&_block) else send(_method) end)
          raise AuthError.new 'No profiles avaliable' if profiles.empty?

          # preload resources
          proxy = ControllerProxy.new self
          proxy.preload_resources_for action_name

          # load test context and execute profile validation
          ctx = TestContext.new proxy
          result = Array(profiles).collect do |profile|
            test_a = _def.validate ctx, profile, controller_name
            raise ForbiddenError if test_a == :forbidden
            test_b = _def.validate ctx, profile, "#{controller_name}##{action_name}" # TODO: keep this?
            raise ForbiddenError if test_b == :forbidden
            test_a == :allowed or test_b == :allowed
          end
          raise AuthError unless result.any?
        end
      end

      ## Removes protection for all controller actions.
      def uncan_all
        self._cn_excluded = :all
      end

      ## Removes protection for the especified controller actions.
      #
      # @param [splat] _excluded List of actions to be excluded.
      #
      def uncanned(*_excluded)
        self._cn_excluded ||= []
        self._cn_excluded.push(*_excluded)
      end

      ## Registers a canned actor
      #
      # @param [String] _name Actor's name and generator method name if no block is given.
      # @param [Hash] _options Options:
      #     * as: If given, this si used as actor's name and _name is only used for generator retrieval.
      # @param [Block] _block generator block, used instead of generator method if given.
      #
      def register_actor(_name, _options={}, &_block)
        self._cn_actors ||= ActiveSupport::HashWithIndifferentAccess.new
        self._cn_actors[_options.fetch(:as, _name)] = _block || _name
      end

      ## Loads a resource
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
      def load_resource(_name, _options={}, &_block)
        self._cn_resources ||= ActiveSupport::HashWithIndifferentAccess.new
        self._cn_resources << {
          name: _name,
          only: unless _options[:only].nil? then Array(_options[:only]) else nil end,
          except: Array(_options[:except]),
          loader: _block || Proc.new { eval(_name.to_s.camelize).find params[_options.fetch(:using, :id)] }
        }
      end

      def load_all_resources
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
          raise SetupError.new "Invalid actor loader value" if loader.nil?
          actor = if loader.is_a? String then @controller.send(loader) else @controller.instance_eval(&loader) end
          @actor_cache[_name] = actor
        end

        def has_key?(_key)
          @actor_loaders.has_key? _key.to_sym
        end
      end
    end
  end
end