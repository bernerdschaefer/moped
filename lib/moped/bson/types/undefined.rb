module Moped
  module BSON
    module Types
      class Undefined
        def self.===(other)
          other == self
        end

        def self.decode(decoder)
          warn "Undefined is deprecated"
          self
        end

        def self.encode(*)
          warn "Undefined is deprecated"
        end

        def self.type_code
          6
        end

        def self.__bson_type__
          self
        end
      end
    end
  end
end
