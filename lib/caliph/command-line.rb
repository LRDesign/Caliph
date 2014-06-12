require 'caliph/define-op'
require 'caliph/command-run-result'

module Caliph
  class CommandLine
    include DefineOp

    class << self
      attr_accessor :output_stream
    end

    def initialize(executable, *options)
      @output_stream = self.class.output_stream || $stderr
      @executable = executable.to_s
      @options = options
      @redirections = []
      @env = {}
      yield self if block_given?
    end

    attr_accessor :name, :executable, :options, :env, :output_stream
    attr_reader :redirections

    alias_method :command_environment, :env

    def set_env(name, value)
      command_environment[name] = value
      return self
    end

    def verbose
      #::Rake.verbose && ::Rake.verbose != ::Rake::FileUtilsExt::DEFAULT
    end

    def name
      @name || executable
    end

    # The command as a string, including arguments and options
    def command
      ([executable] + options_composition + @redirections).join(" ")
    end

    # The command as a string, including arguments and options, plus prefixed
    # environment variables.
    def string_format
      (command_environment.map do |key, value|
        [key, value].join("=")
      end + [command]).join(" ")
    end

    def options_composition
      options
    end

    def redirect_to(stream, path)
      @redirections << "#{stream}>#{path}"
      self
    end

    def redirect_from(path, stream)
      @redirections << "#{stream}<#{path}"
    end

    def copy_stream_to(from, to)
      @redirections << "#{from}>&#{to}"
    end

    def redirect_stdout(path)
      redirect_to(1, path)
    end

    def redirect_stderr(path)
      redirect_to(2, path)
    end

    def redirect_stdin(path)
      redirect_from(path, 0)
    end

    def redirect_both(path)
      redirect_stdout(path).redirect_stderr(path)
    end

    # Run the command, wait for termination, and collect the results.
    # Returns an instance of CommandRunResult that contains the output
    # and exit code of the command.
    #
    # This version adds some information to STDOUT to document that the
    # command is running.  For a terser version, call #execute directly
    def run
      report string_format + " ", false
      result = execute
      report "=> #{result.exit_code}"
      report result.format_streams if verbose
      return result
    ensure
      report "" if verbose
    end

    # Fork a new process for the command, then terminate our process.
    def run_as_replacement
      output_stream.puts "Ceding execution to: "
      output_stream.puts string_format
      Process.exec(command_environment, command)
    end
    alias replace_us run_as_replacement

    # Run the command in the background.  The command can survive the caller.
    def run_detached
      pid, out, err = spawn_process
      Process.detach(pid)
      return pid, out, err
    end
    alias spin_off run_detached

    # Run the command, wait for termination, and collect the results.
    # Returns an instance of CommandRunResult that contains the output
    # and exit code of the command.
    #
    def execute
      collect_result(*spawn_process)
    end

    # Run the command in parallel with the parent process - will kill it if it
    # outlasts us
    def run_in_background
      pid, out, err = spawn_process
      Process.detach(pid)
      at_exit do
        kill_process(pid)
      end
      return pid, out, err
    end
    alias background run_in_background

    # Given a process ID for a running command and a pair of stdout/stdin
    # streams, records the results of the command and returns them in a
    # CommandRunResult instance.
    def collect_result(pid, host_stdout, host_stderr)
      result = CommandRunResult.new(pid, self)
      result.streams = {1 => host_stdout, 2 => host_stderr}
      result.wait
      return result
    end


    def kill_process(pid)
      Process.kill("INT", pid)
    end

    def complete(pid, out, err)
      kill_process(pid)
      collect_result(pid, out, err)
    end

    def report(message, newline=true)
      output_stream.print(message + (newline ? "\n" : ""))
    end


    def succeeds?
      run.succeeded?
    end

    def must_succeed!
      run.must_succeed!
    end

    def spawn_process
      host_stdout, cmd_stdout = IO.pipe
      host_stderr, cmd_stderr = IO.pipe

      pid = Process.spawn(command_environment, command, :out => cmd_stdout, :err => cmd_stderr)
      cmd_stdout.close
      cmd_stderr.close

      return pid, host_stdout, host_stderr
    end


  end


end
