require 'caliph/command-line'

module Caliph
  class MockCommandResult < CommandRunResult
    def self.create(*args)
      if args.length == 1
        args = [args[0], {1 => ""}]
      end

      if String == args[1]
        args[1] = {1 => args[1]}
      end

      return self.new(*args)
    end

    def initialize(code, streams)
      @streams = streams
      @exit_code = code
    end

    attr_reader :exit_code, :streams

    alias exit_status exit_code
  end

  class MockShell
    def self.execute(command_line, *args)
      execute_string(command_line.string_format)
    end

    def self.execute_string(string)
      fail "Command line executed in specs without 'expect_command' or 'expect_some_commands' (string was: #{string})"
    end
  end

  module CommandLineExampleGroup
    include CommandLineDSL
    module MockingExecute
      def execute(command)
        Caliph::MockShell.execute(command)
      end
    end

    def self.included(group)
      group.before :each do
        @original_execute = Caliph::Shell.instance_method(:execute)
        @reporting_stream = StringIO.new
        unless MockingExecute > Caliph::Shell
          Caliph::Shell.send(:include, MockingExecute)
        end
        Caliph::Shell.send(:remove_method, :execute)
        Caliph::Shell.any_instance.stub(:output_stream => @reporting_stream)
      end

      group.after :each do
        Caliph::Shell.send(:define_method, :execute, @original_execute)
      end
    end

    #Registers indifference as to exactly what commands get called
    def expect_some_commands
      Caliph::MockShell.should_receive(:execute_string).any_number_of_times.and_return(MockCommandResult.create(0))
    end

    #Registers an expectation about a command being run - expectations are
    #ordered
    def expect_command(cmd, *result)
      Caliph::MockShell.should_receive(:execute_string, :expected_from => caller(1)[0]).with(cmd).ordered.and_return(MockCommandResult.create(*result))
    end
  end
end
