class Object
  def to_b
    case self
    when true, false then self
    when nil then false
    else
      to_i != 0
    end
  end
end

class String
  TRUE_REGEXP = /^(yes|true|on|t|1|\-1)$/i.freeze
  FALSE_REGEXP = /^(no|false|off|f|0)$/i.freeze

  def to_b
    case self
    when TRUE_REGEXP then true
    when FALSE_REGEXP then false
    else
      to_i != 0
    end
  end
end
