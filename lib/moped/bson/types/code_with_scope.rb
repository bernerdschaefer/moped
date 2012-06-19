module Moped
  module BSON
    module Types
      module CodeWithScope
        def self.decode(decoder)
          length = decoder.read_int32
          code = decoder.read_string
          scope = Document.decode(decoder)

          Code.new(code, scope)
        end

        def self.encode(code, encoder)
          encoder.begin_message
          encoder.write_string code

          Document.encode(code.scope, encoder)
          encoder.end_message
        end

        def self.type_code
          15
        end
      end
    end
  end
end
