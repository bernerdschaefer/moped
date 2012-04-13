require "socket"

class ConnectionManager

  def initialize(servers)
    @timeout = 1
    @servers = servers
    @clients = []
  end

  def next_client
    connections = (@servers + @clients).reject do |conn|
      conn.to_io.closed?
    end

    readable, _, errors = IO.select(connections, nil, @clients, @timeout)
    return unless readable || errors

    errors.each do |client|
      client.close
      @clients.delete client
    end

    clients, servers = readable.partition { |s| s.class == TCPSocket }

    servers.each do |server|
      @clients << server.accept
    end

    closed, open = clients.partition &:eof?
    closed.each { |client| @clients.delete client }

    if client = open.shift
      server = lookup_server(client)

      return server, client
    else
      nil
    end
  end

  def lookup_server(client)
    port = client.addr(false)[1]

    @servers.find do |server|
      server.to_io.addr[1] == port
    end
  end

end

servers = [TCPServer.new(0), TCPServer.new(0), TCPServer.new(0)]
manager = ConnectionManager.new(servers)

loop do
  server, client = manager.next_client

  if server
    puts "Message for #{server.addr[1]}: #{client.gets}"
  else
    Thread.pass
  end
end

class Node
  def initialize(set)
  end

  def start
    @server = TCPServer.new 0
  end

  def stop
    @server.close
    @server = nil
  end

  def proxy(client, mongo)
    incoming_message = client.read(16)
    length, op_code = incoming_message.unpack("l<x8l<")
    incoming_message << client.read(length - 16)

    if op_code == OP_QUERY && ismaster_command?(incoming_message)
      # Intercept the ismaster command and send our own reply.
      client.write status_reply
    else
      # This is a normal command, so proxy it to the real mongo instance.
      mongo.write incoming_message

      if op_code == OP_QUERY || op_code == OP_GETMORE
        outgoing_message = mongo.read(4)
        length, = outgoing_message.unpack('l<')
        outgoing_message << mongo.read(length - 4)

        client.write outgoing_message
      end
    end
  end

  def to_io
    @server
  end
end

