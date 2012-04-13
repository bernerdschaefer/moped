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

class Context

  delegate :safety, :safe, :consistency, to: :@session

  def query(database, collection, selector, options = {})
    options[:flags] |= :slave_ok if consistency == :eventual

    with_node do |node|
      node.query(database, collection, selector, options)
    end
  end

  def insert(database, collection, documents, options = {})
    with_node do |node|
      if safe?
        node.pipeline do
          node.insert(database, collection, documents, options)
          node.command("admin", { getlasterror: 1 }.merge(safety))
        end
      else
        node.insert(database, collection, documents, options)
      end
    end
  end

  def get_more(*args)
    raise NotImplementedError, "#get_more cannot be called on Context; it must be called directly on a node"
  end

  def with_node
    if consistency == :eventual
      replica_set.with_secondary do |node|
        yield node
      end
    else
      replica_set.with_primary do |node|
        yield node
      end
    end
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

  def pipeline
    Threaded.begin :pipeline

    begin
      yield
    ensure
      Threaded.end :pipeline
    end

    flush unless Threaded.executing? :pipeline
  end

  private

  def connect() end
  def down!() end
  def ensure_connected() end

  def process(operation, &callback)
    if Threaded.executing? :pipeline
      queue.push [operation, callback]
    else
      flush([operation, callback])
    end
  end

  def queue
    Threaded.stack(:pipelined_operations)
  end

  def flush(ops = queue)
    operations, callbacks = ops.transpose

    logging(operations) do
      ensure_connected do
        connection.write operations
        replies = connection.receive_replies(operations)

        replies.zip(callbacks).map do |reply, callback|
          callback[reply] if callback
        end
      end
    end
  ensure
    ops.clear
  end

end
