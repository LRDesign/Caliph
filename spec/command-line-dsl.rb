require 'caliph/command-line-dsl'

describe Caliph::CommandLineDSL do
  include described_class

  describe "using the - operator" do
    let :command do
      cmd("sudo") - ["gem", "install", "bundler"]
    end

    it "should define commands" do
      command.should be_an_instance_of(Caliph::WrappingChain)
      command.should have(2).commands
      command.commands[0].should be_an_instance_of(Caliph::CommandLine)
      command.commands[1].should be_an_instance_of(Caliph::CommandLine)
      command.command.should == "sudo -- gem install bundler"
    end
  end

  describe "using the | operator" do
    let :command do
      cmd("cat", "/etc/passwd") | ["grep", "root"]
    end

    it "should define commands" do
      command.should be_an_instance_of(Caliph::PipelineChain)
      command.should have(2).commands
      command.commands[0].should be_an_instance_of(Caliph::CommandLine)
      command.commands[1].should be_an_instance_of(Caliph::CommandLine)
      command.command.should == "cat /etc/passwd | grep root"
    end
  end

  describe "using the & operator" do
    let :command do
      p method(:cmd).source_location
      cmd("cd", "/tmp/trash") & %w{rm -rf *}
    end

    it "should define commands" do
      command.should be_an_instance_of(Caliph::PrereqChain)
      command.should have(2).commands
      command.commands[0].should be_an_instance_of(Caliph::CommandLine)
      command.commands[1].should be_an_instance_of(Caliph::CommandLine)
      command.command.should == "cd /tmp/trash && rm -rf *"
    end
  end
end
