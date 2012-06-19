class Fixnum
  attr_writer :__bson_type_for_code__

  def __bson_type_for_code__
    raise "#{self} is not a known bson type code" unless @__bson_type_for_code__
    @__bson_type_for_code__
  end
end

class String
  def __bson_type__
    Moped::BSON::Types::String
  end
end

class Regexp
  def __bson_type__
    Moped::BSON::Types::Regexp
  end
end

class Symbol
  def __bson_type__
    Moped::BSON::Types::Symbol
  end
end

class Array
  def __bson_type__
    Moped::BSON::Types::Array
  end
end

class Time
  def __bson_type__
    Moped::BSON::Types::DateTime
  end
end

class NilClass
  def __bson_type__
    Moped::BSON::Types::Null
  end
end

class TrueClass
  def __bson_type__
    Moped::BSON::Types::Boolean
  end
end

class FalseClass
  def __bson_type__
    Moped::BSON::Types::Boolean
  end
end

class Hash
  def __bson_type__
    Moped::BSON::Types::Document
  end
end

class Float
  def __bson_type__
    Moped::BSON::Types::Double
  end
end

class Integer
  def __bson_type__
    if self > Moped::BSON::Types::Int32::MIN && self < Moped::BSON::Types::Int32::MAX
      Moped::BSON::Types::Int32
    elsif self > Moped::BSON::Types::Int64::MIN && self < Moped::BSON::Types::Int64::MAX
      Moped::BSON::Types::Int64
    else
      raise TypeError, "#{self} cannot be serialized as a 32- or 64-bit integer"
    end
  end
end

#### FIXME #####

class TrueClass
  def __safe_options__
    { safe: true }
  end
end

class Object
  def __safe_options__
    self
  end
end

class FalseClass
  def __safe_options__
    false
  end
end

