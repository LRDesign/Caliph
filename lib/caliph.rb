module Caliph
  def self.new
    Shell.new
  end
end

require 'caliph/command-line'
require 'caliph/command-chain'
require 'caliph/command-line-dsl'
require 'caliph/shell-escaped'
require 'caliph/shell'
