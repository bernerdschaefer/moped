module Moped
  module BSON
    module Types
      module Array
        def self.encode(array, encoder)
          encoder.begin_document

          array.each_with_index do |value, index|
            type = value.__bson_type__

            encoder.write_byte type.type_code
            encoder.write_cstring index
            type.encode(value, encoder)
          end

          encoder.end_document
        end

        def self.decode(decoder)
          length = decoder.read_int32
          array = []

          while (type_code = decoder.read_byte) != 0
            decoder.read_cstring # ignore key
            array << TYPE_MAP[type_code].decode(decoder)
          end

          array
        end

        def self.type_code
          4
        end
      end
    end
  end
end
