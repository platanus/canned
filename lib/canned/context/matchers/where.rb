module Canned
  module Context
    module Matchers
      module Where

        class WhereCtx
          def initialize(_stack)
            @stack = _stack
          end

          def method_missing(_method, *_args, &_block)
            if _args.count == 0 and _block.nil?
              begin
                return @stack.resolve(_method)
              rescue Canned::InmmutableStack::NotFound; end
            end
            super
          end
        end

        ## Executes a given block using current resources.
        #
        #    Examples:
        #       upon { the(:actor) { loads(:resource).where { actor.res_id == resource.id } } }
        #
        # @param [Block] _block Block to be evaluated.
        # @returns [Boolean] True if conditions are met.
        #
        def where(&_block)
          return false unless indeed?
          WhereCtx.new(@stack).instance_eval(&_block)
        end
      end
    end
  end
end