module Moped
  module BSON
    module Types
      class DBPointer < ::String
        def self.encode(pointer, encoder)
          warn "DBPointer is deprecated"

          encoder.write_bytes pointer
        end

        def self.decode(decoder)
          warn "DBPointer is deprecated"

          new(decoder.read_string + decoder.read_bytes(12))
        end

        def self.type_code
          12
        end

        def __bson_type__
          self.class
        end
      end
    end
  end
end
