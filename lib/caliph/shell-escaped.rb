require 'caliph/command-line'

module Caliph
  class ShellEscaped < CommandLine
    def initialize(cmd)
      @escaped = cmd
    end

    def command
      "'" + @escaped.string_format.gsub(/'/,"\'") + "'"
    end

    def command_environment
      {}
    end

    def name
      @name || @escaped.name
    end

    def to_s
      command
    end
  end
end
