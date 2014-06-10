module Caliph
  module CommandLineDSL
    def cmd(*args, &block)
      CommandLine.new(*args, &block)
    end

    def escaped_command(*args, &block)
      ShellEscaped.new(CommandLine.new(*args, &block))
    end
  end
end
