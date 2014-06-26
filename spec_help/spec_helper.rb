require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'rspec'
require 'rspec/core/formatters/base_formatter'

$:.unshift("./lib")

require 'caliph'
require 'cadre/rspec3'

RSpec.configure do |config|
  config.backtrace_inclusion_patterns = []
  config.run_all_when_everything_filtered = true
  config.add_formatter(Cadre::RSpec3::NotifyOnCompleteFormatter)
  config.add_formatter(Cadre::RSpec3::QuickfixFormatter)
end
