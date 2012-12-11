require 'canned/context/base'
require 'canned/context/matchers/where'
require 'canned/context/matchers/has'
require 'canned/context/matchers/is'
require 'canned/context/matchers/that'
require 'canned/context/matchers/relation'

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