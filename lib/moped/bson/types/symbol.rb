module Moped
  module BSON
    module Types
      module Symbol
        def self.encode(symbol, encoder)
          encoder.write_string symbol
        end

        def self.decode(decoder)
          decoder.read_string.intern
        end

        def self.type_code
          14
        end
      end
    end
  end
end
