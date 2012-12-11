require 'canned/context/base'
require 'canned/context/matchers/where'
require 'canned/context/matchers/plus'

module Canned
  module Context
    class Multi < Base
      include Matchers::Where
      include Matchers::Plus
    end
  end
end