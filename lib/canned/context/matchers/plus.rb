module Canned
  module Context
    module Matchers
      module Plus

        ## Very similar to **Load.load**, but does not accepts a block and
        # returns **multi** context that only allows to execute where operations
        def plus(_name, _options={})
          _chain_context(Canned::Context::Multi, nil) do |stack|
            resource = @ctx.resources[_resource]
            return false if resource.nil?
            @stack.push(:resource, _options.fetch(:as, _name), resource)
          end
        end

      end
    end
  end
end