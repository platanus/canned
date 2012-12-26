module Canned
  module Context
    module Matchers
      module Load

        ## Loads a resource and returns a resource context.
        #
        # @param [String|Symbol] _name Resource name
        # @param [Hash] _options Various options:
        #     * as: If given, the resource will use **as** as alias for **where** blocks instead of the name.
        # @param [Block] _block If given, then the block will be evaluated in the resource context and the result
        # of that returned by this function.
        #
        def loaded(_name, _options={}, &_block)
          _chain_context(Canned::Context::Resource, _block) do |stack|
            res = @ctx.resources[_name]
            next false if res.nil?
            stack.push(:resource, _options.fetch(:as, _name), res)
          end
        end

        alias :loads :loaded
      end
    end
  end
end