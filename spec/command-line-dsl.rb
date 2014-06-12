require 'caliph/command-line-dsl'

describe Caliph::CommandLineDSL do
  include described_class

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
      p method(:cmd).source_location
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
