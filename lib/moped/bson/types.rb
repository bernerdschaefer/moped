require "moped/bson/types/array"
require "moped/bson/types/binary"
require "moped/bson/types/boolean"
require "moped/bson/types/code"
require "moped/bson/types/code_with_scope"
require "moped/bson/types/datetime"
require "moped/bson/types/db_pointer"
require "moped/bson/types/document"
require "moped/bson/types/double"
require "moped/bson/types/int32"
require "moped/bson/types/int64"
require "moped/bson/types/max_key"
require "moped/bson/types/min_key"
require "moped/bson/types/null"
require "moped/bson/types/object_id"
require "moped/bson/types/regexp"
require "moped/bson/types/string"
require "moped/bson/types/symbol"
require "moped/bson/types/timestamp"
require "moped/bson/types/undefined"

module Moped
  module BSON
    TYPE_MAP = {}
  end
end

Moped::BSON::Types.constants.each do |name|
  type = Moped::BSON::Types.const_get(name)

  Moped::BSON::TYPE_MAP[type.type_code] = type
end
