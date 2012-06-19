module Moped
  module BSON
    module Types
      module Int64
        MIN = -2**63
        MAX =  2**63 - 1

        def self.encode(int, encoder)
          encoder.write_int64 int
        end

        def self.decode(decoder)
          decoder.read_int64
        end

        def self.type_code
          18
        end
      end
    end
  end
end
