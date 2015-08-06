
Object.class_eval do
  def to_b
    case self
      when true, false then self
      when nil then false
      else
        to_i != 0
    end
  end
end
