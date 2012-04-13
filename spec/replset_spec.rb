require "spec_helper"

describe "Replica Sets" do

  before(:all) do
    @replica_set = Support::ReplicaSetSimulator.new
    @replica_set.start
  end

  after(:all) do
    @replica_set.stop
  end

  before(:each) do
    @primary, @secondaries = @replica_set.initiate
  end

  it "works" do
    cluster = Moped::Cluster.new @replica_set.nodes.map(&:address)

    cluster.sync
    cluster.primaries.map(&:port).should eq [@primary.port]
    cluster.secondaries.map(&:port).should =~ [
      @secondaries[0].port,
      @secondaries[1].port
    ]

    @primary.demote

    cluster.sync
    cluster.primaries.should be_empty
    cluster.secondaries.map(&:port).should =~ [
      @primary.port,
      @secondaries[0].port,
      @secondaries[1].port
    ]

    @secondaries[0].promote

    cluster.sync
    cluster.primaries.map(&:port).should eq [@secondaries[0].port]
    cluster.secondaries.map(&:port).should =~ [
      @primary.port,
      @secondaries[1].port
    ]

    cluster.socket_for(:read)
    cluster.socket_for(:write)

    @secondaries[0].stop
    cluster.socket_for(:read)
    lambda do
      cluster.socket_for(:write)
    end.should raise_error

    @secondaries[0].start
    cluster.sync
    cluster.socket_for(:read)
    lambda do
      cluster.socket_for(:write)
    end.should_not raise_error
  end

end
