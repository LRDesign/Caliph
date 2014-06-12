require 'caliph'

describe Caliph::CommandRunResult do
  let :commandline do
    Caliph::CommandLine.new('echo', "-n") do |cmd|
      cmd.options << "Some text"
    end
  end

  let :result do
    commandline.run
  end

  it "should have a result code" do
    expect(result.exit_code).to eq(0)
  end

  it "should have stdout" do
    expect(result.stdout).to eq("Some text")
  end
end
