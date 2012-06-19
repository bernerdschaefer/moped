module Moped
  module BSON
    module Types
      class MaxKey
        class << self
          def ===(other)
            other == self
          end

          def decode(decoder)
            self
          end

          def encode(*)
          end

          def type_code
            127
          end

          def __bson_type__
            self
          end
        end
      end
    end
  end
end
