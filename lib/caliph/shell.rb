require 'caliph/describer'

module Caliph
  class Error < StandardError; end
  class IncompleteCommand < Error; end
  class InvalidCommand < Error; end

  # Operates something like a command line shell, except from a Ruby object
  # perspective.
  #
  # Basically, a Shell operates as your handle on creating, running and killing
  # commands in Caliph.
  #
  class Shell
    attr_accessor :verbose, :output_stream

    def output_stream
      @output_stream ||= $stderr
    end

    def verbose
      @verbose ||= false
    end

    # Reports messages if verbose is true. Used internally to print messages
    # about running commands
    def report_verbose(message)
      report(message) if verbose
    end

    # Prints information to {output_stream} which defaults to $stderr.
    def report(message, newline=true)
      output_stream.print(message + (newline ? "\n" : ""))
    end

    # Kill processes given a raw pid. In general, prefer
    # {CommandRunResult#kill}
    # @param pid the process id to kill
    def kill_process(pid)
      Process.kill("INT", pid)
    rescue Errno::ESRCH
      warn "Couldn't find process #{pid} to kill it"
    end

    def normalize_command_line(*args, &block)
      command_line = nil
      if args.empty? or args.first == nil
        command_line = CommandLine.new
      elsif args.all?{|arg| arg.is_a? String}
        command_line = CommandLine.new(*args)
      else
        command_line = args.first
      end
      if block_given?
        command_line = Describer.new(command_line).describe(&block)
      end
      #raise InvalidCommand, "not a command line: #{command_line.inspect}"
      #unless command_line.is_a? CommandLine
      raise IncompleteCommand, "cannot run #{command_line}" unless command_line.valid?
      command_line
    end
    protected :normalize_command_line

    # Given a process ID for a running command and a pair of stdout/stdin
    # streams, records the results of the command and returns them in a
    # CommandRunResult instance.
    def collect_result(command, pid, host_stdout, host_stderr)
      result = CommandRunResult.new(pid, command, self)
      result.streams = {1 => host_stdout, 2 => host_stderr}
      return result
    end

    # Creates a process to run a command. Handles connecting pipes to stardard
    # streams, launching the process and returning a pid for it.
    # @return [pid, host_stdout, host_stderr] the process id and streams
    #   associated with the child process
    def spawn_process(command_line)
      host_stdout, cmd_stdout = IO.pipe
      host_stderr, cmd_stderr = IO.pipe

      pid = Process.spawn(command_line.command_environment, command_line.command, :out => cmd_stdout, :err => cmd_stderr)
      cmd_stdout.close
      cmd_stderr.close

      return pid, host_stdout, host_stderr
    end

    # Run the command, wait for termination, and collect the results.
    # Returns an instance of CommandRunResult that contains the output
    # and exit code of the command.
    #
    def execute(command_line)
      result = collect_result(command_line, *spawn_process(command_line))
      result.wait
      result
    end

    # @!group Running Commands
    # Run the command, wait for termination, and collect the results.
    # Returns an instance of CommandRunResult that contains the output
    # and exit code of the command. This version {#report}s some information to document that the
    # command is running.  For a terser version, call {#execute} directly
    #
    # @!macro normalized
    #   @yield [CommandLine] command about to be run (for configuration)
    #   @return [CommandRunResult] used to refer to and inspect the resulting
    #     process
    #   @overload $0(&block)
    #   @overload $0(cmd, &block)
    #     @param [CommandLine] execute
    #   @overload $0(*cmd_strings, &block)
    #     @param [Array<String>] a set of strings to parse into a {CommandLine}
    def run(*args, &block)
      command_line = normalize_command_line(*args, &block)

      report command_line.string_format + " ", false
      result = execute(command_line)
      report "=> #{result.exit_code}"
      report_verbose result.format_streams
      return result
    ensure
      report_verbose ""
    end

    # Completely replace the running process with a command. Good for setting
    # up a command and then running it, without worrying about what happens
    # after that. Uses `exec` under the hood.
    # @macro normalized
    # @example Using replace_us
    #   # The last thing we'll ever do:
    #   shell.run_as_replacement('echo', "Everything is okay")
    #   # don't worry, we never get here.
    #   shell.run("sudo", "shutdown -h now")
    def run_as_replacement(*args, &block)
      command_line = normalize_command_line(*args, &block)

      report "Ceding execution to: "
      report command_line.string_format
      Process.exec(command_line.command_environment, command_line.command)
    end
    alias replace_us run_as_replacement

    # Run the command in the background.  The command can survive the caller.
    # Works, for instance, to kick off some long running processes that we
    # don't care about. Note that this isn't quite full daemonization - we
    # don't close the streams of the other process, or scrub its environment or
    # anything.
    # @macro normalized
    def run_detached(*args, &block)
      command_line = normalize_command_line(*args, &block)

      pid, out, err = spawn_process(command_line)
      Process.detach(pid)
      return collect_result(command_line, pid, out, err)
    end
    alias spin_off run_detached

    # Run the command in parallel with the parent process - will kill it if it
    # outlasts us. Good for running e.g. a web server that we need to interact
    # with, or the like, without cluttering the system with a bunch of zombies.
    # @macro normalized
    def run_in_background(*args, &block)
      command_line = normalize_command_line(*args, &block)

      pid, out, err = spawn_process(command_line)
      Process.detach(pid)
      at_exit do
        kill_process(pid)
      end
      return collect_result(command_line, pid, out, err)
    end
    alias background run_in_background

    # !@endgroup
  end
end
