require "moped/bson/encoder"
require "moped/bson/decoder"
require "moped/bson/extensions"
require "moped/bson/types"

module Moped

  # The module for Moped's BSON implementation.
  module BSON

    UTF8_ENCODING = Encoding.find('utf-8')

    class << self

      def encode(document, encoder = Encoder.new)
        Types::Document.encode(document, encoder)

        encoder.flush
      end

      def decode(buffer)
        Types::Document.decode(Decoder.new(buffer))
      end

      # Create a new object id from the provided string.
      #
      # @example Create a new object id.
      #   Moped::BSON::ObjectId("4faf83c7dbf89b7b29000001")
      #
      # @param [ String ] string The string to use.
      #
      # @return [ ObjectId ] The object id.
      #
      # @since 1.0.0
      def ObjectId(string)
        ObjectId.from_string(string)
      end
    end

    Binary = Types::Binary
    Code = Types::Code
    MinKey = Types::MinKey
    MaxKey = Types::MaxKey
    ObjectId = Types::ObjectId
  end
end
