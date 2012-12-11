module Canned
  module Context
    ## Base class for other context types
    class Base

      def initialize(_ctx, _ext, _stack)
        @ctx = _ctx
        @ext = _ext
        @stack = _stack
      end

      ## The method missing callback is used to hook extensions provided by context.
      def method_missing(_method, *_args, &_block)
        ext = @ext[_method]
        return super if ext.nil?
        instance_exec(*_args, &exc)
      end

      ## Returns true if context is in a "loaded" state
      def indeed?
        return @stack != false
      end

    private

      def _chain_context(_klass, _proc)
        # this is the preferred way of changing the context type
        # should be called by matchers that wish to change the context.
        stack = if @stack then yield @stack else false end

        if _proc.nil? then _klass.new(@ctx, @ext, stack)
        elsif stack then _klass.new(@ctx, @ext, stack).instance_eval &_proc
        else false end
      end

    end
  end
end