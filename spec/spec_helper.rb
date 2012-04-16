require "java" if RUBY_PLATFORM == "java"
require "rspec"

$:.unshift((Pathname(__FILE__).dirname.parent + "lib").to_s)

require "moped"
require "support/replica_set_simulator"
require "support/stats"

RSpec.configure do |config|
  Support::Stats.install!

  config.include Support::ReplicaSetSimulator::Helpers, replica_set: true
end
