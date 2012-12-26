module Canned
  module Context
    class Multi < Base
      include Matchers::Where
      include Matchers::Plus
    end
  end
end