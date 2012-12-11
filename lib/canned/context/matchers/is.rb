require 'canned/context/matchers/helpers'

module Canned
  module Context
    module Matchers
      module Is
        ## Test an expression or property
        #
        #    Examples:
        #       when { a(:calculator).is(:is_open?) }
        #       when { the(:user).is('level > 20') }
        #
        # @param [String|Symbol] _key The value of _key is resolved in the current context object.
        # @returns [Boolean] True if conditions are met
        #
        def is(_key)
          return false unless indeed?
          Helpers.resolve(@stack.top, _key)
        end

        alias :are :is
      end
    end
  end
end