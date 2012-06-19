module Moped
  module BSON
    module Types
      module Document
        def self.encode(hash, encoder)
          encoder.begin_document

          hash.each do |key, value|
            type = value.__bson_type__

            encoder.write_byte type.type_code
            encoder.write_cstring key
            type.encode(value, encoder)
          end

          encoder.end_document
        end

        def self.decode(decoder)
          length = decoder.read_int32
          document = {}

          while (type_code = decoder.read_byte) != 0
            key = decoder.read_cstring
            document[key] = TYPE_MAP[type_code].decode(decoder)
          end

          document
        end

        def self.type_code
          3
        end
      end
    end
  end
end
