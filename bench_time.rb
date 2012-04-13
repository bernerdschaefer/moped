require "benchmark"
$:.unshift "./lib"
require "moped/bson"

Benchmark.bmbm do |x|
  x.report "OBjectId.new" do
    100_000.times do
      Moped::BSON::ObjectId.new
    end
  end
end
