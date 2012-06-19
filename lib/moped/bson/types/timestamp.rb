module Moped
  module BSON
    module Types
      class Timestamp < ::String
        def self.decode(decoder)
          new decoder.read_bytes(8)
        end

        def self.encode(timestamp, encoder)
          encoder.write_bytes timestamp
        end

        def self.type_code
          17
        end

        def __bson_type__
          self.class
        end
      end
    end
  end
end
