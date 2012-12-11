require 'canned/context/base'
require 'canned/context/matchers/where'
require 'canned/context/matchers/has'
require 'canned/context/matchers/is'
require 'canned/context/matchers/that'
require 'canned/context/matchers/asks_for'
require 'canned/context/matchers/asks_with'
require 'canned/context/matchers/load'

module Canned
  module Context

    class Actor < Base
      include Matchers::Where
      include Matchers::Has
      include Matchers::Is
      include Matchers::That
      include Matchers::AsksFor
      include Matchers::AsksWith
      include Matchers::Load

      def asks_with_same_id(*_args)
        _args.all? { |a| asks_with_id(a).equal_to(own: a) }
      end

      def asks_with_same(*_args)
        _args.all? { |a| asks_with(a).equal_to(own: a) }
      end

      def owns(_resource, _options={})
        loads(_resource).that_belongs_to_it(_options)
      end

      def belongs_to(_resource, _options={})
        loads(_resource).to_which_it_belongs(_options)
      end

    end
  end
end