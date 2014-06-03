require 'caliph/command-line'

module Caliph
  class MockCommandResult < CommandLine::CommandRunResult
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

  class CommandLine
    def self.execute(*args)
      fail "Command line executed in specs without 'expect_command' or 'expect_some_commands'"
    end
  end

  module CommandLineExampleGroup
    include CommandLineDSL
    module MockingExecute
      def execute
        Caliph::CommandLine.execute(command)
      end
    end


    def self.included(group)
      group.before :each do
        @original_execute = Caliph::CommandLine.instance_method(:execute)
        unless MockingExecute > Caliph::CommandLine
          Caliph::CommandLine.send(:include, MockingExecute)
        end
        Caliph::CommandLine.send(:remove_method, :execute)
      end

      group.after :each do
        Caliph::CommandLine.send(:define_method, :execute, @original_execute)
      end
    end

    #Registers indifference as to exactly what commands get called
    def expect_some_commands
      Caliph::CommandLine.should_receive(:execute).any_number_of_times.and_return(MockCommandResult.create(0))
    end

    #Registers an expectation about a command being run - expectations are
    #ordered
    def expect_command(cmd, *result)
      Caliph::CommandLine.should_receive(:execute, :expected_from => caller(1)[0]).with(cmd).ordered.and_return(MockCommandResult.create(*result))
    end
  end
end