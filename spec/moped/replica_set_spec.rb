require "spec_helper"

describe Moped::ReplicaSet, replica_set: true do
  let(:replica_set) do
    Moped::ReplicaSet.new(seeds, {})
  end

  context "when the replica set hasn't connected yet" do
    describe "#with_primary" do
      it "connects and yields the primary node" do
        replica_set.with_primary do |node|
          node.address.should eq @primary.address
        end
      end
    end

    describe "#with_secondary" do
      it "connects and yields a secondary node" do
        replica_set.with_secondary do |node|
          @secondaries.map(&:address).should include node.address
        end
      end
    end

    context "and the primary is down" do
      before do
        @primary.stop
      end

      describe "#with_primary" do
        it "raises a connection error" do
          lambda do
            replica_set.with_primary do |node|
              node.command "admin", ping: 1
            end
          end.should raise_exception(Moped::ConnectionError)
        end
      end

      describe "#with_secondary" do
        it "connects and yields a secondary node" do
          replica_set.with_secondary do |node|
            @secondaries.map(&:address).should include node.address
          end
        end
      end
    end

    context "and a single secondary is down" do
      before do
        @secondaries.first.stop
      end

      describe "#with_primary" do
        it "connects and yields the primary node" do
          replica_set.with_primary do |node|
            node.address.should eq @primary.address
          end
        end
      end

      describe "#with_secondary" do
        it "connects and yields a secondary node" do
          replica_set.with_secondary do |node|
            node.address.should eq @secondaries.last.address
          end
        end
      end
    end

    context "and all secondaries are down" do
      before do
        @secondaries.each &:stop
      end

      describe "#with_primary" do
        it "connects and yields the primary node" do
          replica_set.with_primary do |node|
            node.address.should eq @primary.address
          end
        end
      end

      describe "#with_secondary" do
        it "connects and yields the primary node" do
          replica_set.with_secondary do |node|
            node.address.should eq @primary.address
          end
        end
      end
    end
  end

  context "when the replica set is connected" do
    before do
      replica_set.refresh
    end

    describe "#with_primary" do
      it "connects and yields the primary node" do
        replica_set.with_primary do |node|
          node.address.should eq @primary.address
        end
      end
    end

    describe "#with_secondary" do
      it "connects and yields a secondary node" do
        replica_set.with_secondary do |node|
          @secondaries.map(&:address).should include node.address
        end
      end
    end

    context "and the primary is down" do
      before do
        @primary.stop
      end

      describe "#with_primary" do
        it "raises a connection error" do
          lambda do
            replica_set.with_primary do |node|
              node.command "admin", ping: 1
            end
          end.should raise_exception(Moped::ConnectionError)
        end
      end

      describe "#with_secondary" do
        it "connects and yields a secondary node" do
          replica_set.with_secondary do |node|
            @secondaries.map(&:address).should include node.address
          end
        end
      end
    end

    context "and a single secondary is down" do
      before do
        @secondaries.first.stop
      end

      describe "#with_primary" do
        it "connects and yields the primary node" do
          replica_set.with_primary do |node|
            node.address.should eq @primary.address
          end
        end
      end

      describe "#with_secondary" do
        it "connects and yields a secondary node" do
          replica_set.with_secondary do |node|
            node.command "admin", ping: 1
            node.address.should eq @secondaries.last.address
          end
        end
      end
    end

    context "and all secondaries are down" do
      before do
        @secondaries.each &:stop
      end

      describe "#with_primary" do
        it "connects and yields the primary node" do
          replica_set.with_primary do |node|
            node.address.should eq @primary.address
          end
        end
      end

      describe "#with_secondary" do
        it "connects and yields the primary node" do
          replica_set.with_secondary do |node|
            node.command "admin", ping: 1
            node.address.should eq @primary.address
          end
        end
      end
    end
  end
end
