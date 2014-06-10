module Caliph
  module DefineOp
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def define_chain_op(opname, klass)
        define_method(opname) do |other|
          unless CommandLine === other
            other = CommandLine.new(*[*other])
          end
          chain = nil
          if klass === self
            chain = self
          else
            chain = klass.new
            chain.add(self)
          end
          chain.add(other)
        end
      end

      def define_op(opname)
        CommandLine.define_chain_op(opname, self)
      end
    end
  end
end
