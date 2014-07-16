require 'caliph/describer'
module Caliph
  module CommandLineDSL
    def cmd(*args, &block)
      cmd = CommandLine.new(*args)
      if block_given?
        cmd = Describer.new(cmd).describe(&block)
      end
      return cmd
    end

    def escaped_command(*args, &block)
      ShellEscaped.new(CommandLine.new(*args, &block))
    end
  end
end
