module Canned
  module Context
    module Matchers
      module AsksWith

        ## Loads a value context for a given parameter
        #
        # @param [String|Symbol] Parameter key
        # @param [Hash] _options Various options:
        #     * as: If given, the value will use this value as alias for **where** blocks instead of the key.
        # @param [Block] _block If given, then the block will be evaluated in the value context and the result
        # of that returned by this function.
        #
        def asked_with(_key, _options={}, &_block)
          _chain_context(Canned::Context::Value, _block) do |stack|
            param = @ctx.params[_key]
            break false if param.nil?
            stack.push :value, _options.fetch(:as, _key), param
          end
        end
        alias :asks_with :asked_with

        ## Same as **asked_with** but transforms parameter to an int.
        def asked_with_id(_key, _options={}, &_block)
          _chain_context(Canned::Context::Value, _block) do |stack|
            param = @ctx.params[_key]
            break false if param.nil?
            stack.push :value, _options.fetch(:as, _key), param.to_i
          end
        end
        alias :asks_with_id :asked_with_id

      end
    end
  end
end