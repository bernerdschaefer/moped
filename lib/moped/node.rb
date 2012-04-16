module Moped
  class ReplicaSetReconfigured < StandardError; end

  class Node

    attr_reader :host
    attr_reader :port
    attr_reader :timeout

    def initialize(address)
      host, port = address.split(":")
      @host = host
      @port = port.to_i
      @timeout = 5
    end

    def command(database, cmd, options = {})
      operation = Protocol::Command.new(database, cmd, options)

      process(operation) do |reply|
        result = reply.documents[0]

        raise Errors::OperationFailure.new(
          operation, result
        ) if result["ok"] != 1 || result["err"] || result["errmsg"]

        result
      end
    end

    def kill_cursors(cursor_ids)
      process Protocol::KillCursors.new(cursor_ids)
    end

    def get_more(database, collection, cursor_id, limit)
      process Protocol::GetMore.new(database, collection, cursor_id, limit)
    end

    def remove(database, collection, selector, options = {})
      process Protocol::Delete.new(database, collection, selector, options)
    end

    def update(database, collection, selector, change, options = {})
      process Protocol::Update.new(database, collection, selector, change, options)
    end

    def insert(database, collection, documents)
      process Protocol::Insert.new(database, collection, documents)
    end

    def query(database, collection, selector, options = {})
      process Protocol::Query.new(database, collection, selector, options)
    end

    # @return [true/false] whether the node needs to be refreshed.
    def needs_refresh?(time)
      !@refreshed_at || @refreshed_at < time
    end

    def address
      "#{@host}:#{@port}"
    end

    def peers
      []
    end

    def primary?
      @primary
    end

    def secondary?
      @secondary
    end

    # Refresh information about the node, such as it's status in the replica
    # set and it's known peers.
    #
    # Returns nothing.
    # Raises ConnectionError if the node cannot be reached
    # Raises ReplicaSetReconfigured if the node is no longer a primary node and
    #   refresh was called within an +#ensure_primary+ block.
    def refresh
      info = command "admin", ismaster: 1

      @refreshed_at = Time.now
      primary = true if info["ismaster"]
      secondary = true if info["secondary"]

      @primary, @secondary = primary, secondary

      if !primary && Threaded.executing?(:ensure_primary)
        raise ReplicaSetReconfigured, "#{inspect} is no longer the primary node."
      end
    end

    attr_reader :down_at

    def down?
      @down_at
    end

    # Set a flag on the node for the duration of provided block so that an
    # exception is raised if the node is no longer the primary node.
    #
    # Returns nothing.
    def ensure_primary
      Threaded.begin :ensure_primary
      yield
    ensure
      Threaded.end :ensure_primary
    end

    # Yields the block if a connection can be established, retrying when a
    # connection error is raised.
    #
    # @raises ConnectionError when a connection cannot be established.
    def ensure_connected
      # Don't run the reconnection login if we're already inside an
      # +ensure_connected+ block.
      return yield if Threaded.executing? :connection
      Threaded.begin :connection

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
      rescue
        # Looks like we got an unexpected error, so we'll clean up the connection
        # and re-raise the exception.
        disconnect
        raise
      end
    ensure
      Threaded.end :connection
    end

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

    def initialize_copy(_)
      @connection = nil
    end

    def connection
      @connection ||= Connection.new
    end

    def disconnect
      connection.disconnect
    end

    def connected?
      connection.connected?
    end

    # Mark the node as down.
    #
    # Returns nothing.
    def down!
      @down_at = Time.now
    end

    # Connect to the node.
    #
    # Returns nothing.
    # Raises Moped::ConnectionError if the connection times out.
    # Raises Moped::ConnectionError if the server is unavailable.
    def connect
      connection.connect host, port, timeout
      @down_at = nil

      refresh
    rescue Timeout::Error
      raise ConnectionError, "Timed out connection to Mongo on #{host}:#{port}"
    rescue Errno::ECONNREFUSED
      raise ConnectionError, "Could not connect to Mongo on #{host}:#{port}"
    end

    def process(operation, &callback)
      if Threaded.executing? :pipeline
        queue.push [operation, callback]
      else
        flush([[operation, callback]])
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
            callback ? callback[reply] : reply
          end.last
        end
      end
    ensure
      ops.clear
    end

    def logging(operations)
      instrument_start = (logger = Moped.logger) && logger.debug? && Time.new
      yield
    ensure
      log_operations(logger, operations, Time.new - instrument_start) if instrument_start && !$!
    end

    def log_operations(logger, ops, duration)
      prefix  = "  MOPED: #{host}:#{port} "
      indent  = " "*prefix.length
      runtime = (" (%.1fms)" % duration)

      if ops.length == 1
        logger.debug prefix + ops.first.log_inspect + runtime
      else
        first, *middle, last = ops

        logger.debug prefix + first.log_inspect
        middle.each { |m| logger.debug indent + m.log_inspect }
        logger.debug indent + last.log_inspect + runtime
      end
    end

  end
end
