module Caliph
  class IncompleteCommand < StandardError; end

  class Shell
    attr_accessor :verbose, :output_stream

    def report_verbose(message)
      report(message) if verbose
    end

    def report(message, newline=true)
      output_stream.print(message + (newline ? "\n" : ""))
    end

    def kill_process(pid)
      Process.kill("INT", pid)
    rescue Errno::ESRCH
      warn "Couldn't find process #{pid} to kill it"
    end

    def spawn_process(command_line)
      host_stdout, cmd_stdout = IO.pipe
      host_stderr, cmd_stderr = IO.pipe

      pid = Process.spawn(command_line.command_environment, command_line.command, :out => cmd_stdout, :err => cmd_stderr)
      cmd_stdout.close
      cmd_stderr.close

      return pid, host_stdout, host_stderr
    end

    def normalize_command_line(command_line, &block)
      if command_line.nil?
        command_line = CommandLine.new
        yield command_line
      end
      raise IncompleteCommand, "cannot run #{command_line}" unless command_line.valid?
      command_line
    end

    # Given a process ID for a running command and a pair of stdout/stdin
    # streams, records the results of the command and returns them in a
    # CommandRunResult instance.
    def collect_result(command, pid, host_stdout, host_stderr)
      result = CommandRunResult.new(pid, command)
      result.streams = {1 => host_stdout, 2 => host_stderr}
      return result
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

    # Run the command, wait for termination, and collect the results.
    # Returns an instance of CommandRunResult that contains the output
    # and exit code of the command.
    #
    # This version adds some information to STDOUT to document that the
    # command is running.  For a terser version, call #execute directly
    def run(command_line=nil, &block)
      command_line = normalize_command_line(command_line, &block)

      report command_line.string_format + " ", false
      result = execute(command_line)
      report "=> #{result.exit_code}"
      report_verbose result.format_streams
      return result
    ensure
      report_verbose ""
    end

    # Fork a new process for the command, then terminate our process.
    def run_as_replacement(command_line=nil, &block)
      command_line = normalize_command_line(command_line, &block)

      output_stream.puts "Ceding execution to: "
      output_stream.puts command_line.string_format
      Process.exec(command_line.command_environment, command_line.command)
    end
    alias replace_us run_as_replacement

    # Run the command in the background.  The command can survive the caller.
    def run_detached(command_line=nil, &block)
      command_line = normalize_command_line(command_line, &block)

      pid, out, err = spawn_process(command_line)
      Process.detach(pid)
      return collect_result(command_line, pid, out, err)
    end
    alias spin_off run_detached

    # Run the command in parallel with the parent process - will kill it if it
    # outlasts us
    def run_in_background(command_line=nil, &block)
      command_line = normalize_command_line(command_line, &block)

      pid, out, err = spawn_process(command_line)
      Process.detach(pid)
      at_exit do
        kill_process(pid)
      end
      return collect_result(command_line, pid, out, err)
    end
    alias background run_in_background
  end
end
