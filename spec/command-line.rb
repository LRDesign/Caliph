$stderr.puts "\n#{__FILE__}:#{__LINE__} => #{$".inspect}"
require 'caliph'
require 'caliph/testing/mock-command-line'

require 'caliph/testing/record-commands'

Caliph::CommandLine.command_recording_path = "/dev/null"

describe Caliph::CommandLine do
  let :commandline do
    Caliph::CommandLine.new('echo', "-n") do |cmd|
      cmd.options << "Some text"
    end
  end

  it "should have a name set" do
    commandline.name.should == "echo"
  end

  it "should produce a command string" do
    commandline.command.should == "echo -n Some text"
  end

  it "should succeed" do
    commandline.succeeds?.should be_true
  end

  it "should not complain about success" do
    expect do
      commandline.must_succeed!
    end.to_not raise_error
  end

  describe Caliph::CommandLine::CommandRunResult do
    let :result do
      commandline.run
    end

    it "should have a result code" do
      result.exit_code.should == 0
    end

    it "should have stdout" do
      result.stdout.should == "Some text"
    end
  end
end

describe Caliph::CommandLine, "setting environment variables" do
  let :commandline do
    Caliph::CommandLine.new("env") do |cmd|
      cmd.env["TEST_ENV"] = "indubitably"
    end
  end

  let :result do
    commandline.run
  end

  it "should succeed" do
    result.succeeded?.should be_true
  end

  it "should alter the command's environment variables" do
    result.stdout.should =~ /TEST_ENV.*indubitably/
  end

end

describe Caliph::PipelineChain do
  let :commandline do
    Caliph::PipelineChain.new do |chain|
      chain.add Caliph::CommandLine.new("env")
      chain.add Caliph::CommandLine.new("cat") do |cmd|
        cmd.env["TEST_ENV"] = "indubitably"
      end
    end
  end

  let :result do
    commandline.run
  end

  it "should produce the right command" do
    commandline.command.should == 'env | cat'
  end

  it "should produce a runnable command with format_string" do
    commandline.string_format.should == 'TEST_ENV=indubitably env | cat'
  end

  it "should succeed" do
    result.succeeded?.should be_true
  end

  it "should alter the command's environment variables" do
    result.stdout.should =~ /TEST_ENV.*indubitably/
  end
end


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

describe Caliph::CommandLine, "that fails" do
  let :commandline do
    Caliph::CommandLine.new("false")
  end

  it "should not succeed" do
    commandline.succeeds?.should == false
  end

  it "should raise error if succeed demanded" do
    expect do
      commandline.must_succeed
    end.to raise_error
  end
end
