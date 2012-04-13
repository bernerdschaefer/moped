module Moped
  class Session

    # @api private
    class Context
      extend Forwardable

      def initialize(session)
        @session = session
      end

      delegate :safety => :@session
      delegate :safe?  => :@session
      delegate :consistency  => :@session
      delegate :replica_set  => :@session

      def query(database, collection, selector, options = {})
        if consistency == :eventual
          options[:flags] ||= []
          options[:flags] |= [:slave_ok]
        end

        with_node do |node|
          node.query(database, collection, selector, options)
        end
      end

      def command(database, command)
        with_node do |node|
          node.command(database, command)
        end
      end

      def insert(database, collection, documents)
        with_node do |node|
          if safe?
            node.pipeline do
              node.insert(database, collection, documents)
              node.command("admin", { getlasterror: 1 }.merge(safety))
            end
          else
            node.insert(database, collection, documents)
          end
        end
      end

      def update(database, collection, selector, change, options = {})
        with_node do |node|
          if safe?
            node.pipeline do
              node.update(database, collection, selector, change, options)
              node.command("admin", { getlasterror: 1 }.merge(safety))
            end
          else
            node.update(database, collection, selector, change, options)
          end
        end
      end

      def remove(database, collection, selector, options = {})
        with_node do |node|
          if safe?
            node.pipeline do
              node.remove(database, collection, selector, options)
              node.command("admin", { getlasterror: 1 }.merge(safety))
            end
          else
            node.remove(database, collection, selector, options)
          end
        end
      end

      def get_more(*args)
        raise NotImplementedError, "#get_more cannot be called on Context; it must be called directly on a node"
      end

      def kill_cursors(*args)
        raise NotImplementedError, "#kill_cursors cannot be called on Context; it must be called directly on a node"
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

  end
end
