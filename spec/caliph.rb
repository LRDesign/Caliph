require 'caliph'

describe Caliph do
  it "should return a Shell from ::new" do
    expect(Caliph.new).to be_a Caliph::Shell
  end
end
