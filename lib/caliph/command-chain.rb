module Caliph
  class CommandChain
    def initialize
      @commands = []
      @command_environment = {}
      super(nil)
    end

    attr_reader :commands

    def add(cmd)
      yield cmd if block_given?
      @commands << cmd
      self
    end

    #Honestly this is sub-optimal - biggest driver for considering the
    #mini-shell approach here.
    def command_environment
      @command_environment = @commands.reverse.inject(@command_environment) do |env, command|
        env.merge(command.command_environment)
      end
    end

    def name
      @name || @commands.last.name
    end
  end

  class WrappingChain < CommandChain
    define_op('-')

    def command
      @commands.map{|cmd| cmd.command}.join(" -- ")
    end
  end

  class PrereqChain < CommandChain
    define_op('&')

    def command
      @commands.map{|cmd| cmd.command}.join(" && ")
    end
  end

  class PipelineChain < CommandChain
    define_op('|')

    def command
      @commands.map{|cmd| cmd.command}.join(" | ")
    end
  end
end

