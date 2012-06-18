require "moped/bson/assertions"

module Moped
  module BSON
    class Encoder
      class Error < StandardError; end

      include Moped::BSON::Assertions

      INT32_MIN = -2**31
      INT32_MAX =  2**31 - 1

      INT64_MIN = -2**63
      INT64_MAX =  2**63 - 1

      DOUBLE_MIN = -Math::E**-37
      DOUBLE_MAX =  Math::E**37

      def initialize
        @data, @pack = [], []
      end

      def flush
        out = @data.pack(@pack.join)

        @data.clear
        @pack.clear

        out
      end

      def write_cstring(string)
        string = utf8_encode(string)

        refute string.include?("\x00"),
          "Expected cstring not to include a null byte"

        write_bytes string
        write_null_byte
      end

      def write_string(string)
        string = utf8_encode(string)

        write_int32 string.bytesize + 1
        write_bytes string
        write_null_byte
      end

      def write_int32(int)
        assert int >= INT32_MIN || int <= INT32_MAX,
          "Expected 32-bit integer to be within INT32_MIN..INT32_MAX"

        write int, 'l<'
      end

      def write_int64(int)
        assert int >= INT64_MIN || int <= INT64_MAX,
          "Expected 64-bit integer to be within INT64_MIN..INT64_MAX"

        write int, 'q<'
      end

      def write_double(double)
        assert double >= DOUBLE_MIN || double <= DOUBLE_MAX,
          "Expected double to be within DOUBLE_MIN..DOUBLE_MAX"

        write double, 'E'
      end

      def write_bytes(bytes)
        write bytes, 'a*'
      end

      def write_byte(byte)
        write byte, 'C'
      end

      def write_null_byte
        write nil, 'x'
      end

      private

      def write(data, pack)
        @data << data if data
        @pack << pack
      end

      def utf8_encode(value)
        # Optimistically attempt to encode the provided string as UTF-8.
        value.encode('utf-8')
      rescue EncodingError
        # The input string can't be automatically encoded as utf-8, but that
        # doesn't mean it's not valid utf-8 data and just mis-tagged, so we try
        # forcing the encoding and then validating it.
        data = value.dup.force_encoding('utf-8')

        assert data.valid_encoding?,
          "Expected string to be valid utf-8"

        data
      end
    end
  end
end
