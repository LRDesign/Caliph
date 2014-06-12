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
    expect(commandline.name).to eq("echo")
  end

  it "should produce a command string" do
    expect(commandline.command).to eq("echo -n Some text")
  end

  it "should succeed" do
    expect(commandline.succeeds?).to be_truthy
  end

  it "should not complain about success" do
    expect do
      commandline.must_succeed!
    end.to_not raise_error
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
    expect(result.succeeded?).to be_truthy
  end

  it "should alter the command's environment variables" do
    expect(result.stdout).to match(/TEST_ENV.*indubitably/)
  end

end

describe Caliph::CommandLine, 'redirecting' do
  let :commandline do
    Caliph::CommandLine.new("env")
  end

  let :result do
    commandline.string_format
  end

  it 'should allow redirect stdout' do
    commandline.redirect_stdout('some_file')
    expect(result).to match(/1>some_file$/)
  end

  it 'should allow redirect stderr' do
    commandline.redirect_stderr('some_file')
    expect(result).to match(/2>some_file$/)
  end

  it 'should allow chain redirects' do
    commandline.redirect_stdout('stdout_file').redirect_stderr('stderr_file')
    expect(result).to match(/\b1>stdout_file\b/)
    expect(result).to match(/\b2>stderr_file\b/)
  end

  it 'should redirect both' do
    commandline.redirect_both('output_file')
    expect(result).to match(/\b1>output_file\b/)
    expect(result).to match(/\b2>output_file\b/)
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
    expect(commandline.command).to eq('env | cat')
  end

  it "should produce a runnable command with format_string" do
    expect(commandline.string_format).to eq('TEST_ENV=indubitably env | cat')
  end

  it "should succeed" do
    expect(result.succeeded?).to be_truthy
  end

  it "should alter the command's environment variables" do
    expect(result.stdout).to match(/TEST_ENV.*indubitably/)
  end
end



describe Caliph::CommandLine, "that fails" do
  let :commandline do
    Caliph::CommandLine.new("false")
  end

  it "should not succeed" do
    expect(commandline.succeeds?).to eq(false)
  end

  it "should raise error if succeed demanded" do
    expect do
      commandline.must_succeed
    end.to raise_error
  end
end
