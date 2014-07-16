require 'caliph/command-line-dsl'

describe Caliph::CommandLineDSL do
  include described_class

  describe "complex commands in a block" do
    let :command do
      cmd("cd", "/tmp/trash") do |cmd|
        cmd.redirect_stderr "file1"
        cmd &= %w{rm -rf *}
        cmd.redirect_stderr "file2"
      end #=> returns whole chain
    end

    it "should define commands" do
      expect(command).to be_a(Caliph::CommandChain)
      expect(command.commands.size).to eq(2)
      expect(command.commands[0]).to be_an_instance_of(Caliph::CommandLine)
      expect(command.commands[1]).to be_an_instance_of(Caliph::CommandLine)
      expect(command.command).to eq("cd /tmp/trash 2>file1 && rm -rf * 2>file2")
    end
  end

  describe "using the - operator" do
    let :command do
      cmd("sudo") - ["gem", "install", "bundler"]
    end

    it "should define commands" do
      expect(command).to be_an_instance_of(Caliph::WrappingChain)
      expect(command.commands.size).to eq(2)
      expect(command.commands[0]).to be_an_instance_of(Caliph::CommandLine)
      expect(command.commands[1]).to be_an_instance_of(Caliph::CommandLine)
      expect(command.command).to eq("sudo -- gem install bundler")
    end
  end

  describe "using the | operator" do
    let :command do
      cmd("cat", "/etc/passwd") | ["grep", "root"]
    end

    it "should define commands" do
      expect(command).to be_an_instance_of(Caliph::PipelineChain)
      expect(command.commands.size).to eq(2)
      expect(command.commands[0]).to be_an_instance_of(Caliph::CommandLine)
      expect(command.commands[1]).to be_an_instance_of(Caliph::CommandLine)
      expect(command.command).to eq("cat /etc/passwd | grep root")
    end
  end

  describe "using the & operator" do
    let :command do
      cmd("cd", "/tmp/trash") & %w{rm -rf *}
    end

    it "should define commands" do
      expect(command).to be_an_instance_of(Caliph::PrereqChain)
      expect(command.commands.size).to eq(2)
      expect(command.commands[0]).to be_an_instance_of(Caliph::CommandLine)
      expect(command.commands[1]).to be_an_instance_of(Caliph::CommandLine)
      expect(command.command).to eq("cd /tmp/trash && rm -rf *")
    end
  end
end
