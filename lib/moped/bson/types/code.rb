module Moped
  module BSON
    module Types
      class Code

        attr_reader :code, :scope

        def initialize(code, scope=nil)
          @code = code
          @scope = scope
        end

        def scoped?
          !!scope
        end

        def ==(other)
          self.class === other && code == other.code && scope == other.scope
        end
        alias eql? ==

        def hash
          [code, scope].hash
        end

        alias to_s code

        # @private
        def self.decode(decoder)
          new decoder.read_string
        end

        # @private
        def self.encode(code, encoder)
          encoder.write_string code
        end

        # @private
        def self.type_code; 13; end

        # @private
        def __bson_type__
          scoped? ? Types::CodeWithScope : Types::Code
        end

      end
    end
  end
end
