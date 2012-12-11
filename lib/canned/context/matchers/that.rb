require 'canned/context/matchers/helpers'

module Canned
  module Context
    module Matchers
      module That

        def that(&_block)
          if _block
            instance_eval &_block
          else self end
        end

        def that_all(&_block)
          # TODO
        end

        def that_any(&_block)
          # TODO
        end

      end
    end
  end
end