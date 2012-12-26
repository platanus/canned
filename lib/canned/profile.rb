module Canned

  ## Holds a profile definition and provides the **validate** method
  #
  # This class instances are populated using the **ProfileDsl**.
  #
  # profile :hola do
  #   context { the(:user) }
  #   context { a(:raffle) }
  #
  #   allow 'index', upon(:admin) { loads(:) where {  } } }
  #   allow 'index', upon { the(:user_id) { is } and a(:raffle).is }
  #   allow 'show', upon { is :is_allowed? and has() and a(:apron).has(:id).same_as(own: :id) asks_for(:) and owns(:raffle) } }
  # end
  #
  class Profile

    attr_accessor :context
    attr_accessor :rules

    def initialize
      @context = nil
      @rules = []
    end

    def validate(_base, _actions)

      # TODO: optimize, do not process allow rules if already allowed.

      # run the context block if given
      # TODO: check base type when a context is used?
      _base = _base.instance_eval &@context if @context

      @rules.each do |rule|
        case rule[:type]
        when :allow
          if rule[:action].nil? or _actions.include? rule[:action]
            return :allowed if rule[:proc].nil? or _base.instance_eval(&rule[:proc])
          end
        when :forbid
          if rule[:action].nil? or _actions.include? rule[:action]
            return :forbidden if rule[:proc].nil? or _base.instance_eval(&rule[:proc])
          end
        when :continue
          # continue block's interrupt flow if false
          return :break unless _base.instance_eval(&rule[:proc])
        when :expand
          # when evaluating an cross profile call, any special condition will cause to break.
          result = rule[:profile].validate(_base, _actions)
          return result if result != :default
        when :scope
          # when evaluating a child block, only break if a matching allow or forbid is found.
          result = rule[:profile].validate(_base, _actions)
          return result if result != :default and result != :break
        end
      end

      # No rule matched, return not allowed.
      return :default
    end
  end
end