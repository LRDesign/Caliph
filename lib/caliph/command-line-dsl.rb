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
      command = nil
      if args.length == 1 and args.first.is_a? CommandLine
        command = args.first
      else
        command = cmd(*args, &block)
      end
      ShellEscaped.new(command)
    end
  end
end
