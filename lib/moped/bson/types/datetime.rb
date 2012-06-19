module Moped
  module BSON
    module Types
      module DateTime
        def self.encode(time, encoder)
          encoder.write_int64 time.to_f * 1000
        end

        def self.decode(decoder)
          seconds, fragment = decoder.read_int64.divmod 1000
          Time.at(seconds, fragment * 1000).utc
        end

        def self.type_code
          9
        end
      end
    end
  end
end
