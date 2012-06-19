module Moped
  module BSON
    module Types
      module Int32
        MIN = -2**31
        MAX =  2**31 - 1

        def self.encode(int, encoder)
          encoder.write_int32 int
        end

        def self.decode(decoder)
          decoder.read_int32
        end

        def self.type_code
          16
        end
      end
    end
  end
end
