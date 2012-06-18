require "moped/bson/assertions"

module Moped
  module BSON
    class Decoder
      class Error < StandardError; end

      include Moped::BSON::Assertions

      attr_accessor :buffer, :pos, :buffer_length

      def initialize(buffer)
        @buffer = buffer
        @buffer_length = @buffer.length
        @pos = 0
      end

      def read_cstring
        assert index = @buffer.index("\x00", @pos),
          "Expected cstring to end with a null byte"

        string = utf8_decode read_bytes(index - @pos)

        assert read_byte == 0,
          "Expected cstring to end with a null byte"

        string
      end

      def read_string
        string = utf8_decode read_bytes(read_int32 - 1)

        assert read_byte == 0,
          "Expected string to end with a null byte"

        string
      end

      def read_int32
        read_bytes(4).unpack('l<')[0]
      end

      def read_int64
        read_bytes(8).unpack('q<')[0]
      end

      def read_double
        read_bytes(8).unpack('E')[0]
      end

      def read_bytes(bytes)
        assert @pos + bytes < buffer_length,
          "Expected #{bytes} bytes to be available"

        current, @pos = @pos, @pos + bytes

        @buffer[current, bytes]
      end

      def read_byte
        assert @pos < buffer_length,
          "Expected 1 byte to be available"

        current, @pos = @pos, @pos + 1

        @buffer.getbyte current
      end

      private

      def utf8_decode(value)
        value.force_encoding('utf-8')
      end
    end
  end
end
