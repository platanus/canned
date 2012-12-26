module Canned
  module Context
    class Resource < Base
      include Matchers::Where
      include Matchers::Has
      include Matchers::Is
      include Matchers::That
      include Matchers::Relation
    end
  end
end