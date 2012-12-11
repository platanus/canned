require 'canned/context/matchers/helpers'
require 'canned/context/value'

module Canned
  module Context
    module Matchers
      module AsksFor

        ## Tests the action name
        #
        # @param [String|Symbol] _actions actions that will return true
        # @returns [Boolean] true if current action matches any one of **_actions**
        #
        def asked_for(*_actions)
          _actions.any? { |a| a.to_s == @ctx.action_name }
        end
        alias :asks_for :asked_for

      end
    end
  end
end