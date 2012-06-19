module Moped
  module BSON
    module Types
      module Null
        def self.encode(*)
        end

        def self.decode(*)
          nil
        end

        def self.type_code
          10
        end
      end
    end
  end
end
