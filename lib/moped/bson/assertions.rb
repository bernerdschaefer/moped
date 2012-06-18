module Moped
  module BSON
    module Assertions

      def refute(test, message)
        assert !test, message
      end

      def assert(test, message)
        raise self.class::Error, message unless test
      end

    end
  end
end

