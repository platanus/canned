module Canned
  module Context
    module Matchers
      module Relation

        def to_which_it_belongs(_options={})
          return false unless indeed?

          actor = @stack.top(:actor)
          raise Canned::SetupError.new '"to_which_it_belongs" require an enclosing actor context' if actor.nil?

          resource = @stack.top

          as = _options[:as]
          as = resource.class.name.parameterize if as.nil?

          if actor.respond_to? :reflect_on_association
            assoc = actor.reflect_on_association(as)
            raise Canned::SetupError.new 'Invalid association name' if assoc.nil?
            raise Canned::SetupError.new 'Thorugh assoc is not supported' if assoc.options.has_key? :through # TODO: support through!
            raise Canned::SetupError.new 'Invalid association type' if assoc.macro != :belongs_to
            actor.send(assoc.foreign_key) == resource.id
          else
            Helpers.resolve(resource, :id) == Helpers.resolve(actor, "#{as}_id".to_sym)
          end
        end

        def that_belongs_to_it(_options={})
          return false unless indeed?

          actor = @stack.top(:actor)
          raise Canned::SetupError.new '"that_belongs_to_it" require an enclosing actor context' if actor.nil?
          resource = @stack.top

          as = _options[:as]
          as = resource.class.name.parameterize if as.nil?

          if resource.respond_to? :reflect_on_association
            assoc = resource.reflect_on_association(as)
            raise Canned::SetupError.new 'Invalid association name' if assoc.nil?
            raise Canned::SetupError.new 'Thorugh assoc is not supported' if assoc.options.has_key? :through # TODO: support through!
            raise Canned::SetupError.new 'Invalid association type' if assoc.macro != :belongs_to
            resource.send(assoc.foreign_key) == actor.id
          else
            Helpers.resolve(actor, :id) == Helpers.resolve(resource, "#{as}_id".to_sym)
          end
        end

      end
    end
  end
end