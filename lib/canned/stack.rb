module Canned

  ## Implements an inmmutable stack where every operation generates a new stack
  #
  # Used by the test contexts to hold the subject stack.
  #
  class InmmutableStack

    class NotFound < Exception; end

    ## Class used to hold stack entries
    class Entry

      attr_reader :tag # entry tag
      attr_reader :name # entry name
      attr_reader :obj # entry data

      def initialize(_tag, _name, _obj)
        @tag = _tag
        @name = _name.to_s
        @obj = _obj
      end
    end

    def initialize(_entry=nil, _tail=nil)
      @stack = if _tail then _tail.entries else [] end
      @stack << _entry if _entry
    end

    ## Gets a copy of the internal stack state.
    #
    def entries; @stack.clone; end

    ## Returns true if stack is empty
    def empty?; @stack.empty?; end

    ## Creates a new stack using the current stack as tail.
    #
    def push(_tag, _name, _value)
      InmmutableStack.new Entry.new(_tag, _name, _value), self
    end

    ## Retrieves the top value of the stack
    #
    def top(_tag=nil)
      return @stack.last.obj if _tag.nil?
      @stack.reverse_each do |item|
        return item.obj if item.tag == _tag
      end
      return nil
    end

    ## Resolves a stack value by it's name
    #
    def resolve(_name)
      _name = _name.to_s
      @stack.reverse_each do |item|
        return item.obj if item.name == _name
      end
      raise NotFound
    end
  end
end