module Moped
  module BSON
    module Types
      class Binary < ::String

        SUBTYPE_MAP = {
          generic:  "\x00".ord,
          function: "\x01".ord,
          old:      "\x02".ord,
          uuid:     "\x03".ord,
          md5:      "\x05".ord,
          user:     "\x80".ord
        }

        attr_reader :type

        def initialize(type, data)
          @type = type

          super data
        end

        alias data to_s

        def ==(other)
          self.class === other && data == other.data && type == other.type
        end
        alias eql? ==

        def hash
          [self, type].hash
        end

        def inspect
          "#<#{self.class.name} type=#{type.inspect} length=#{length}>"
        end

        # @private
        def self.decode(decoder)
          length = decoder.read_int32
          type = SUBTYPE_MAP.invert[decoder.read_byte]

          if type == :old
            length -= 4
            decoder.read_int32
          end

          data = decoder.read_bytes length
          new(type, data)
        end

        # @private
        def self.encode(binary, encoder)
          if binary.type == :old
            encoder.write_int32 binary.length + 4
            encoder.write_byte SUBTYPE_MAP[binary.type]
            encoder.write_int32 binary.length
            encoder.write_bytes binary
          else
            encoder.write_int32 binary.length
            encoder.write_byte SUBTYPE_MAP[binary.type]
            encoder.write_bytes binary
          end
        end

        # @private
        def self.type_code
          5
        end

        # @private
        def __bson_type__
          self.class
        end

      end
    end
  end
end
