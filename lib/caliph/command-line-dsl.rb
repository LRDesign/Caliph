module Caliph
  module CommandLineDSL
    class Watcher
      attr_accessor :apex

      def inspect
        "Watcher@#{"%#0x" % apex.object_id}"
      end
    end

    def cmd(*args, &block)
      watcher = Watcher.new
      cmd = CommandLine.new(*args)
      cmd.definition_watcher = watcher
      watcher.apex = cmd
      yield cmd if block_given?
      watcher.apex
    end

    def escaped_command(*args, &block)
      ShellEscaped.new(CommandLine.new(*args, &block))
    end
  end
end
