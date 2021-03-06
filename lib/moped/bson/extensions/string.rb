module Moped
  module BSON
    # @private
    module Extensions
      module String
        module ClassMethods
          def __bson_load__(io)
            io.read(*io.read(4).unpack(INT32_PACK)).chop!.force_encoding('utf-8')
          end
        end

        def __bson_dump__(io, key)
          io << Types::STRING
          io << key
          io << NULL_BYTE

          begin
            data = encode('utf-8')
          rescue EncodingError
            data = dup
            data.force_encoding('utf-8')

            raise unless data.valid_encoding?
          end

          data.force_encoding('binary')

          io << [data.bytesize+1].pack(INT32_PACK)
          io << data
          io << NULL_BYTE
        end
      end
    end
  end
end
