require 'canned/context/matchers/helpers'
require 'canned/context/value'

module Canned
  module Context
    module Matchers
      module Has

        ## Acts on one of the top resource's attributes
        #
        #    Examples:
        #       when { loaded(:raffle).has(:app_id) { equal_to(20) or less_than(20) } }
        #       when { loaded(:raffle).has('ceil(upper)').greater_than(20)
        #
        def has(_key, _options={}, &_block)
          _chain_context(Canned::Context::Value, _block) do |stack|
            value = Helpers.resolve(@stack.top, _key)
            stack.push(:value, _options.fetch(:as, _key), _value)
          end
        end

        alias :have :has
      end
    end
  end
end