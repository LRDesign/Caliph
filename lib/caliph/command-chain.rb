require 'caliph/define-op'

module Caliph
  class CommandChain < CommandLine
    include DefineOp

    def initialize
      @commands = []
      @command_environment = {}
      super(nil)
    end

    attr_reader :commands

    def valid?
      commands.all?{|cmd| cmd.valid?}
    end

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

    def redirect_to(stream, path)
      @commands.last.redirect_to(stream, path)
    end

    def redirect_from(path, stream)
      @commands.last.redirect_from(path, stream)
    end

    def copy_stream_to(from, to)
      @commands.last.copy_stream_to(from, to)
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
