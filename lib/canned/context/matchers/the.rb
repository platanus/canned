module Canned
  module Context
    module Matchers
      module The

        ## Loads an actor and returns an actor context.
        #
        # @param [String|Symbol] _name Actor name
        # @param [Hash] _options Various options:
        #     * as: If given, the actor will use **as** as alias for **where** blocks instead of the name.
        # @param [Block] _block If given, then the block will be evaluated in the actor's context and the result
        # of that returned by this function.
        #
        def the(_name, _options={}, &_block)
          _chain_context(Canned::Context::Actor, _block) do |stack|
            actor = @ctx.actors[_name]
            break false if actor.nil?
            stack.push(:actor, _options.fetch(:as, _name), actor)
          end
        end
      end
    end
  end
end