module Moped
  module BSON
    module Types
      module Boolean
        def self.encode(boolean, encoder)
          encoder.write_byte boolean == true ? 1 : 0
        end

        def self.decode(decoder)
          decoder.read_byte == 1
        end

        def self.type_code
          8
        end
      end
    end
  end
end
