require 'canned/context/base'
require 'canned/context/matchers/where'
require 'canned/context/matchers/equality'

module Canned
  module Context
    class Value < Base
      include Matchers::Where
      include Matchers::Equality
    end
  end
end