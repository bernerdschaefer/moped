class Node

  # @return [true/false] whether the node needs to be refreshed.
  def needs_refresh?(time)
    !@refreshed_at || @refreshed_at < time
  end

  def primary?
    @primary
  end

  def secondary?
    @secondary
  end

  # Refreshes information about the Node, such as it's status in the replica
  # set and it's known peers.
  #
  # @raises ConnectionError when the node cannot be reached
  # @raises ReplicaSetReconfigured when the node's role changed within an
  #   +#ensure_primary+ block.
  def refresh
    info = command "admin", ismaster: 1

    @refreshed_at = Time.now
    primary = true if info["ismaster"]
    secondary = true if info["secondary"]

    @primary, @secondary = primary, secondary

    if @ensure_primary && !primary
      raise ReplicaSetReconfigured, "#{inspect} is no longer the primary node."
    end
  end

  # Sets an +ensure_primary+ flag on the node for the duration of the provided
  # block. This causes +#refresh+ to raise a +ReplicaSetReconfigured+ exception
  # if the node is no longer the primary.
  def ensure_primary
    ensure_primary = @ensure_primary
    @ensure_primary = true
    yield
  ensure
    @ensure_primary = ensure_primary
  end

  def connect
    connection.connect host, port, timeout
    @down_at = nil

    refresh
  rescue Timeout::Error
    raise ConnectionError, "Timed out connection to Mongo on #{host}:#{port}"
  rescue Errno::ECONNREFUSED
    raise ConnectionError, "Could not connect to Mongo on #{host}:#{port}"
  end

  # Flags the node as down.
  def down!
    @down_at = Time.now
  end

  def down?
    !!@down_at
  end

  # Yields the block if a connection can be established, retrying when a
  # connection error is raised.
  #
  # @raises ConnectionError when a connection cannot be established.
  def ensure_connected
    inside_ensure_connected = @inside_ensure_connected

    # Don't run the reconnection login if we're already inside an
    # +ensure_connected+ block.
    return yield if inside_ensure_connected
    @inside_ensure_connected = true

    retry_on_failure = true

    begin
      connect unless connected?
      yield
    rescue ReplicaSetReconfigured
      # Someone else wrapped this in an #ensure_primary block, so let the
      # reconfiguration exception bubble up.
      raise
    rescue ConnectionError
      disconnect

      if retry_on_failure
        # Maybe there was a hiccup -- try reconnecting one more time
        retry_on_failure = false
        retry
      else
        # Nope, we failed to connect twice. Flag the node as down and re-raise
        # the exception.
        down!
        raise
      end
    else
      # Looks like we got an unexpected error, so we'll clean up the connection
      # and re-raise the exception.
      disconnect
      raise
    end
  ensure
    @inside_ensure_connected = inside_ensure_connected
  end

end

class ReplicaSet

  # @option options :connect_timeout number of seconds to wait before aborting
  # a connection attempt. (5)
  #
  # @option options :operation_timeout number of seconds to wait before
  # aborting an operation. (nil)
  #
  # @option options :down_interval number of seconds to wait before attempting
  # to reconnect to a down node. (30)
  #
  # @option options :refresh_interval number of seconds to cache information
  # about a node. (300)
  def initialize(hosts, options)
    @options = options
    @nodes = []

    refresh hosts.map { |host| Node.new(host) }
  end

  # Refreshes information for each of the nodes provided. The node list
  # defaults to the list of all known nodes.
  #
  # If a node is successfully refreshed, any newly discovered peers will also
  # be refreshed.
  #
  # @return [Array<Node>] the available nodes
  def refresh(nodes_to_refresh = @nodes)
    refreshed_nodes = []
    seen = {}

    # Set up a recursive lambda function for refreshing a node and it's peers.
    refresh_node = ->(node) do
      return if seen[node]
      seen[node] = true

      # Add the node to the global list of known nodes.
      @nodes << node unless @nodes.include?(node)

      begin
        node.refresh

        # This node is good, so add it to the list of nodes to return.
        refreshed_nodes << node unless refreshed_nodes.include?(node)

        # Now refresh any newly discovered peer nodes.
        (nodes.peers - @nodes).each &refresh_node
      rescue ConnectionError
        # We couldn't connect to the node, so don't do anything with it.
      end
    end

    nodes_to_refresh.each &refresh_node
    refreshed_nodes.to_a
  end

  # Returns the list of available nodes, refreshing 1) any nodes which were
  # down and ready to be checked again and 2) any nodes whose information is
  # out of date.
  #
  # @return [Array<Node>] the list of available nodes.
  def nodes
    # Find the nodes that were down but are ready to be refreshed, or those
    # with stale connection information.
    needs_refresh, available = @nodes.partition do |node|
      (node.down? && node.down_at < (Time.now - @options[:down_internal])) ||
        node.needs_refresh?(Time.now - @options[:refresh_internal])
    end

    # Refresh those nodes.
    available.concat refresh(needs_refresh)

    # Now return all the nodes that are available.
    available
  end

  # Yields the replica set's primary node to the provided block. This method
  # will retry the block in case of connection errors or replica set
  # reconfiguration.
  #
  # @raises ConnectionError when no primary node can be found
  def with_primary(retry_on_failure = true, &block)
    if node = nodes.find &:primary?
      begin
        node.ensure_primary do
          return yield node
        end
      rescue ConnectionError, ReplicaSetReconfigured
        # Fall through to the code below if our connection was dropped or the
        # node is no longer the primary.
      end
    end

    if retry_on_failure
      # We couldn't find a primary node, so refresh the list and try again.
      refresh
      with_primary(false, &block)
    else
      raise ConnectionError, "Could not connect to a primary node for replica set #{inspect}"
    end
  end

  # Yields a secondary node if available, otherwise the primary node. This
  # method will retry the block in case of connection errors.
  #
  # @raises ConnectionError when no secondary or primary node can be found
  def with_secondary(retry_on_failure = true, &block)
    available_nodes = nodes.shuffle!.partition(&:secondary?).flatten

    while node = available_nodes.shift
      begin
        return yield node
      rescue ConnectionError
        # That node's no good, so let's try the next one.
        next
      end
    end

    if retry_on_failure
      # We couldn't find a secondary or primary node, so refresh the list and
      # try again.
      refresh
      with_secondary(false, &block)
    else
      raise ConnectionError, "Could not connect to any secondary or primary nodes for replica set #{inspect}"
    end
  end

end

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
