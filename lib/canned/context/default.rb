require 'canned/context/base'
require 'canned/context/matchers/the'
require 'canned/context/matchers/load'
require 'canned/context/matchers/asks_for'
require 'canned/context/matchers/asks_with'


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