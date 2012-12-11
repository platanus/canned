require 'canned/context/matchers/helpers'

module Canned
  module Context
    module Matchers
      module Helpers

        def self.resolve(_target, _key)
          if _target.is_a? Hash then _target[_key] else _target.send(_key) end
        end

      end
    end
  end
end