require "spec_helper"

describe Moped::Query do
  let(:session) do
    Moped::Session.new %w[127.0.0.1:27017], database: "moped_test", safe: true
  end

  let(:users) do
    session[:users]
  end

  let(:scope) do
    object_id
  end

  let(:documents) do
    [
      { "_id" => Moped::BSON::ObjectId.new, "scope" => scope },
      { "_id" => Moped::BSON::ObjectId.new, "scope" => scope }
    ]
  end

  describe "#limit" do
    it "limits the query" do
      users.insert(documents)
      users.find(scope: scope).limit(1).to_a.should eq [documents.first]
    end
  end

  describe "#skip" do
    it "skips +n+ documents" do
      users.insert(documents)
      users.find(scope: scope).skip(1).to_a.should eq [documents.last]
    end
  end

  describe "#sort" do
    let(:documents) do
      [
        { "_id" => Moped::BSON::ObjectId.new, "scope" => scope, "n" => 0 },
        { "_id" => Moped::BSON::ObjectId.new, "scope" => scope, "n" => 1 }
      ]
    end

    it "sorts the results" do
      users.insert(documents)
      users.find(scope: scope).sort(n: -1).to_a.should eq documents.reverse
    end
  end

  describe "#distinct" do
    let(:documents) do
      [
        { count: 0, scope: scope },
        { count: 1, scope: scope },
        { count: 1, scope: scope }
      ]
    end
    it "returns distinct values for +key+" do
      users.insert(documents)
      users.find(scope: scope).distinct(:count).should =~ [0, 1]
    end
  end

  describe "#select" do
    let(:documents) do
      [
        { "scope" => scope, "n" => 0 },
        { "scope" => scope, "n" => 1 }
      ]
    end

    it "changes the fields returned" do
      users.insert(documents)
      users.find(scope: scope).select(_id: 0).to_a.should eq documents
    end
  end

  describe "#one" do
    before do
      users.insert(documents)
    end

    it "returns the first matching document" do
      users.find(scope: scope).one.should eq documents.first
    end

    it "respects #skip" do
      users.find(scope: scope).skip(1).one.should eq documents.last
    end

    it "respects #sort" do
      users.find(scope: scope).sort(_id: -1).one.should eq documents.last
    end
  end

  describe "#each" do
    it "yields each document" do
      users.insert(documents)
      users.find(scope: scope).each.with_index do |document, index|
        document.should eq documents[index]
      end
    end

    context "with a limit" do
      it "closes open cursors" do
        users.insert(100.times.map { Hash["scope" => scope] })

        stats = Support::Stats.collect do
          users.find(scope: scope).limit(5).entries
        end

        stats["127.0.0.1:27017"].grep(Moped::Protocol::KillCursors).count.should eq 1
      end

    end

    context "with a limit and large result set" do
      it "gets more and closes cursors" do
        11.times do
          users.insert(scope: scope, large_field: "a"*1_000_000)
        end

        stats = Support::Stats.collect do
          users.find(scope: scope).limit(10).entries
        end

        stats["127.0.0.1:27017"].grep(Moped::Protocol::GetMore).count.should eq 1
        stats["127.0.0.1:27017"].grep(Moped::Protocol::KillCursors).count.should eq 1
      end
    end

    context "without a limit" do
      it "fetches more" do
        users.insert(102.times.map { Hash["scope" => scope] })

        stats = Support::Stats.collect do
          users.find(scope: scope).entries
        end

        stats["127.0.0.1:27017"].grep(Moped::Protocol::GetMore).count.should eq 1
      end
    end
  end

  describe "#count" do
    let(:documents) do
      [
        { "_id" => Moped::BSON::ObjectId.new, "scope" => scope },
        { "_id" => Moped::BSON::ObjectId.new, "scope" => scope },
        { "_id" => Moped::BSON::ObjectId.new }
      ]
    end

    it "returns the number of matching document" do
      users.insert(documents)
      users.find(scope: scope).count.should eq 2
    end
  end

  describe "#update" do
    it "updates the first matching document" do
      users.insert(documents)
      users.find(scope: scope).update("$set" => { "updated" => true })
      users.find(scope: scope, updated: true).count.should eq 1
    end
  end

  describe "#update_all" do
    it "updates all matching documents" do
      users.insert(documents)
      users.find(scope: scope).update_all("$set" => { "updated" => true })
      users.find(scope: scope, updated: true).count.should eq 2
    end
  end

  describe "#upsert" do
    context "when a document exists" do
      before do
        users.insert(scope: scope, counter: 1)
      end

      it "updates the document" do
        users.find(scope: scope).upsert("$inc" => { counter: 1 })
        users.find(scope: scope).one["counter"].should eq 2
      end
    end

    context "when no document exists" do
      it "inserts a document" do
        users.find(scope: scope).upsert("$inc" => { counter: 1 })
        users.find(scope: scope).one["counter"].should eq 1
      end
    end
  end

  describe "#remove" do
    it "removes the first matching document" do
      users.insert(documents)
      users.find(scope: scope).remove
      users.find(scope: scope).count.should eq 1
    end
  end

  describe "#remove_all" do
    it "removes all matching documents" do
      users.insert(documents)
      users.find(scope: scope).remove_all
      users.find(scope: scope).count.should eq 0
    end
  end
end
