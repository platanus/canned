require 'canned/context/matchers/helpers'

module Canned
  module Context
    module Matchers
      module Equality

        ## Returns true if a given value equals current context value.
        #
        # @param [Object] _value to compare to.
        # @param [Hash] _options various options:
        #     * own: if set, context value is compared to the closest containing actor context attribute **own**.
        #
        def equal_to(_options={})
          return false unless indeed?
          @stack.top == _equality_load_value(_options)
        end

        ## Works the same as **equal_to** but performs a **greater_than** comparison
        def greater_than(_options={})
          return false unless indeed?
          @stack.top > _equality_load_value(_options)
        end

        ## Works the same as **equal_to** but performs a **less_than** comparison
        def less_than(_options={})
          return false unless indeed?
          @stack.top < _equality_load_value(_options)
        end

      private

        # @api auxiliary
        def _equality_load_value(_options)
          return _options unless _options.is_a? Hash

          own = _options[:own]
          if own
            # use last actor as reference
            actor = @stack.top(:actor)
            raise Canned::SetupError.new '"own" option requires an enclosing actor context' if actor.nil?
            return Helpers.resolve(actor, own)
          end

          return _options[:value]
        end
      end
    end
  end
end