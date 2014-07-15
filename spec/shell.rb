require 'caliph'

describe Caliph::Shell do
  let :output do
    StringIO.new
  end

  let :shell do
    Caliph::Shell.new.tap do |shell|
      shell.output_stream = output
    end
  end

  let :mock_command do
    instance_double(Caliph::CommandLine)
  end

  let :execution do
    instance_double(Caliph::Execution)
  end

  let :mock_status do
    instance_double(Process::Status)
  end

  before :each do
    allow(Process).to receive(:spawn).and_return(100)
    allow(Process).to receive(:detach)
    allow(Process).to receive(:exec)
    allow(Process).to receive(:kill)
    allow(Process).to receive(:waitpid2).and_return([101, mock_status]) #increasingly unhappy
    allow(mock_status).to receive(:exitstatus).and_return(0)
  end

  shared_examples "for a run method" do
    it "should yield a new CommandLine" do
      expect do
        test_run do |cmd|
          expect(cmd).to be_a Caliph::CommandLine
        end
      end.to raise_error(Caliph::IncompleteCommand)
    end

    it "should run valid results of block-defined CommandLines" do
      expect( test_run {|cmd|
          cmd.executable = "grep"
      }).to be_a(Caliph::CommandRunResult)
    end

    it "should run a passed CommandLine" do
      allow(mock_command).to receive(:valid?).and_return(true)
      allow(mock_command).to receive(:string_format).and_return("TESTING='Oh, indeed' echo I'm testing here!")
      allow(mock_command).to receive(:command).and_return("echo I'm testing here!")
      allow(mock_command).to receive(:command_environment).and_return({"TESTING" => "Oh, indeed"})
      expect(test_run(mock_command)).to be_a(Caliph::CommandRunResult)
    end
  end

  describe "#run with strings)" do
    it "should run a passed CommandLine" do
      allow(Caliph::CommandLine).to receive(:new).and_return(mock_command)

      allow(mock_command).to receive(:valid?).and_return(true)
      allow(mock_command).to receive(:string_format).and_return("TESTING='Oh, indeed' echo I'm testing here!")
      allow(mock_command).to receive(:command).and_return("echo I'm testing here!")
      allow(mock_command).to receive(:command_environment).and_return({"TESTING" => "Oh, indeed"})

      expect(shell.run("ls", "-la")).to be_a(Caliph::CommandRunResult)
    end
  end

  describe "#run" do
    def test_run(cmd=nil, &block)
      shell.run(cmd, &block)
    end

    include_examples "for a run method"
  end

  describe "#run_detached" do
    def test_run(cmd=nil, &block)
      shell.run_detached(cmd, &block)
    end
    include_examples "for a run method"
  end

  describe "#run_in_background" do
    def test_run(cmd=nil, &block)
      shell.run_in_background(cmd, &block)
    end
    include_examples "for a run method"
  end

  describe "#run_as_replacement" do
    it "should run valid results of block-defined CommandLines" do
      expect(Process).to receive(:exec)
      shell.run_as_replacement do |cmd|
          cmd.executable = "grep"
        end
    end

    it "should run a passed CommandLine" do
      allow(mock_command).to receive(:valid?).and_return(true)
      allow(mock_command).to receive(:string_format).and_return("TESTING='Oh, indeed' echo I'm testing here!")
      allow(mock_command).to receive(:command).and_return("echo I'm testing here!")
      allow(mock_command).to receive(:command_environment).and_return({"TESTING" => "Oh, indeed"})

      expect(Process).to receive(:exec)
      shell.run_as_replacement(mock_command)
    end

  end

end
