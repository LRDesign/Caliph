require 'caliph/define-op'
require 'caliph/command-run-result'

module Caliph
  class CommandLine
    include DefineOp

    class << self
      attr_accessor :output_stream
    end

    def initialize(executable = nil, *options)
      @output_stream = self.class.output_stream || $stderr
      @executable = executable.to_s unless executable.nil?
      @options = options
      @redirections = []
      @env = {}
      yield self if block_given?
    end

    attr_accessor :name, :executable, :options, :env, :output_stream
    attr_reader :redirections

    alias_method :command_environment, :env

    def valid?
      !@executable.nil?
    end

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

    #:nocov:
    #@deprecated
    def run
      Caliph.new.run(self)
    end

    #@deprecated
    def run_as_replacement
      Caliph.new.run_as_replacement(self)
    end
    alias replace_us run_as_replacement

    #@deprecated
    def run_detached
      Caliph.new.run_detached(self)
    end
    alias spin_off run_detached

    #@deprecated
    def execute
      Caliph.new.execute(self)
    end

    #@deprecated
    def run_in_background
      Caliph.new.run_in_background(self)
    end
    alias background run_in_background

    #@deprecated
    def succeeds?
      run.succeeded?
    end

    #@deprecated
    def must_succeed!
      run.must_succeed!
    end
    #:nocov:
  end
end
