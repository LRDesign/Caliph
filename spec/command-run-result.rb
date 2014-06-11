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
    result.exit_code.should == 0
  end

  it "should have stdout" do
    result.stdout.should == "Some text"
  end
end
