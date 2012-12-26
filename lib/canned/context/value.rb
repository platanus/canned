module Canned
  module Context
    class Value < Resource
      include Matchers::Equality
    end
  end
end