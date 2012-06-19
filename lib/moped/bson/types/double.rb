module Moped
  module BSON
    module Types
      module Double
        MIN = -Math::E**-37
        MAX =  Math::E**37

        def self.encode(float, encoder)
          encoder.write_double float
        end

        def self.decode(decoder)
          decoder.read_double
        end

        def self.type_code
          1
        end
      end
    end
  end
end
