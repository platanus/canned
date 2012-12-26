module Canned
  module Context
    class Default < Base
      include Matchers::The
      include Matchers::Load
      include Matchers::AsksWith
      include Matchers::AsksFor
    end
  end
end