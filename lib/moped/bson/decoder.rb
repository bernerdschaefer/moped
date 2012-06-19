module Moped
  module BSON
    class Decoder < StringIO
      def read_cstring
        gets("\x00").chop!.force_encoding(UTF8_ENCODING)
      end

      def read_string
        read(read_int32).chop!.force_encoding(UTF8_ENCODING)
      end

      def read_int32
        read(4).unpack('l<')[0]
      end

      def read_int64
        read(8).unpack('q<')[0]
      end

      def read_double
        read(8).unpack('E')[0]
      end

      alias read_bytes read
      alias read_byte getbyte

      private

      def utf8_decode(value)
        value.force_encoding('utf-8')
      end
    end
  end
end
