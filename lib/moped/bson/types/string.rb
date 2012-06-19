module Moped
  module BSON
    module Types
      module String
        def self.encode(string, encoder)
          encoder.write_string string
        end

        def self.decode(decoder)
          decoder.read_string
        end

        def self.type_code
          2
        end
      end
    end
  end
end
