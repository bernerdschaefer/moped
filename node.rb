
## speculative

class Collection
  def insert(documents)
    # ...
    session.with_node_for(:write) do |node|
      node.insert database.name, name, documents
    end
  end
end

class Database
  def command(command)
    session.with_node(:write) do |node|
      node.command name, command
    end
  end
end

class Cursor
  def load_initial_result_set
    session.with_node(:read) do |node|
      node.query @query_op
      @node = node
    end
  end

  def get_more
    @node.get_more @get_more_op
  end
end

class SessionNodeProxy
  def initialize(session, node)

  end

  def insert(database, collection, documents, options = {})
    operation = Protocol::SafeOperation.wrap(
      Protocol::Insert.new(database, collection, documents, options),
      session.safety
    )

    node.
  end
end
