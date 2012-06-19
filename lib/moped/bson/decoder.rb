require "moped/bson/assertions"

module Moped
  module BSON
    class Decoder
      class Error < StandardError; end

      include Moped::BSON::Assertions

      attr_accessor :buffer

      def initialize(buffer)
        @buffer = StringIO.new buffer
      end

      def read_cstring
        utf8_decode @buffer.gets("\x00").chop!
      end

      def read_string
        utf8_decode read_bytes(read_int32).chop!
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
        buffer.read bytes
      end

      def read_byte
        buffer.getbyte
      end

      private

      def utf8_decode(value)
        value.force_encoding('utf-8')
      end
    end
  end
end
