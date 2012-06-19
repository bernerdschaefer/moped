module Moped
  module BSON
    module Types
      module Regexp
        def self.encode(regexp, encoder)
          encoder.write_cstring regexp.source

          options = regexp.options
          encoder.write_bytes 'i'  if (options & ::Regexp::IGNORECASE) != 0
          encoder.write_bytes 'ms' if (options & ::Regexp::MULTILINE)  != 0
          encoder.write_bytes 'x'  if (options & ::Regexp::EXTENDED)   != 0
          encoder.write_null_byte
        end

        def self.decode(decoder)
          source = decoder.read_cstring

          options = 0

          while (option = decoder.read_byte) != 0
            case option
            when 105 # 'i'
              options |= ::Regexp::IGNORECASE
            when 109, 115 # 'm', 's'
              options |= ::Regexp::MULTILINE
            when 120 # 'x'
              options |= ::Regexp::EXTENDED
            end
          end

          ::Regexp.new(source, options)
        end

        def self.type_code
          11
        end
      end
    end
  end
end
