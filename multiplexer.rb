require 'socket'
mongo = TCPSocket.new "127.0.0.1", 27017

@timeout = 1
@servers = [TCPServer.new(0), TCPServer.new(0), TCPServer.new(0)]
@connections = []

def get_socket
  ios = IO.select( @servers + @connections, nil, @connections, 1 )
  return unless ios

  # Delete connections with errors
  ios[2].each do |socket|
    socket.close
    @connections.delete socket
  end

  ready_servers, ready_clients = ios[0].partition { |sock| sock.is_a?(TCPServer) }

  ready_servers.each do |server|
    client = server.accept
    @connections << client
    # serve client immediately?
  end

  ready_clients.each do |client|
    if client.eof?
      @connections.delete(client)
    else
      server_port = client.addr(false)[1]
      return client
    end
  end

  nil
end

puts @servers.map { |s| s.addr[1] }

Thread.new do
  loop do
    if socket = get_socket
      message = socket.gets
      socket.puts "hello"
    else
      Thread.pass
    end
  end
end.join
