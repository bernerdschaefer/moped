class Database

  # @consistency strong
  def drop
    session.with(consistency: :strong) do |session|
      session.context.command name, dropDatabase: 1
    end
  end

  # @consistency nil
  def command(cmd) end

end

class Collection

  # @consistency strong
  def drop() end

  # @consistency strong
  def insert() end

end

class Query

  # @consistency nil
  def one
    reply = session.query \
      database.name, collection.name, selector, options.merge(limit: -1)
    reply.documents[0]
  end

  # @consistency nil
  def distinct() end

  # @consistency nil
  def count
    database.command(
      count: collection.name,
      query: selector
    )["n"]
  end

  # @consistency strong
  def update() end

  # @consistency strong
  def update_all() end

  # @consistency strong
  def upsert() end

  # @consistency strong
  def remove() end

  # @consistency strong
  def remove_all() end

end

class Cursor

  # @consistency nil
  def load
    consistency = session.consistency
    @options[:flags] |= :slave_ok if consistency == :eventual

    reply, @node = session.context.with_node do |node|
      [node.query(@database, @collection, @selector, @options), node]
    end

    @limit -= reply.count if limited?
    @cursor_id = reply.cursor_id

    reply.documents
  end

  def get_more
    @node.get_more @database, @collection, @cursor_id, @limit
  end

  def kill
    @node.kill_cursors [@cursor_id]
  end

end

class Node

  def initialize(host, port, options = {}) end

  def command(database, cmd)
    command = Protocol::Command.new(database, cmd)

    process(command) do |reply|
      p reply
    end
  end

  def get_more() end
  def insert() end
  def kill_cursors() end
  def query() end
  def remove() end
  def update() end

  # @api semipublic
  def down?() end
  def down_at() end
  def ensure_primary() end
  def needs_refresh?() end
  def primary?() end
  def refresh() end
  def secondary?() end

  private

  def connect() end
  def down!() end
  def ensure_connected() end


end
