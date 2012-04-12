module Support
  class ReplicaSetSimulator

    def initialize() end
    def start() end

    class Node

      def initialize(host, port)
        @host, @port = host, port
      end

      def ==(other)
        @host == other.host && @port == other.port
      end

      def start() end
      def kill() end
      def hiccup() end
      def demote() end
      def promote() end

    end

  end
end

if __FILE__ == $0
  rs = Support::ReplicaSetSimulator.new
  rs.start

  primary, secondary_1, secondary_2 = rs.nodes
  primary.promote
end
