String.class_eval do

  # Convert DSL string forms into a hash
  # e.g
  #
  #  "{:name => 'autechre'}" =>   Hash['name'] = autechre'
  #  "{:cost_price => '13.45', :price => 23,  :sale_price => 4.23 }"
  #  "{:cost_price => '13.45', :price => 23,  :sale_price => 4.23 }"

  def to_hash_object

    h = {}

    gsub(/[{}]/, '').split(',').each do |e|
      e.strip!

      k, v = if(e.include?('=>'))
               e.split('=>')
             else
               e.split(': ')
             end

      k = k.gsub(/[:']/, '').strip  # easier to treat all keys as strings
      v = v.to_s.strip

      if( v.match(/['"]/) )
        h[k] = v.gsub(/["']/, '')
      elsif( v.match(/^\d+$|^\d*\.\d+$|^\.\d+$/) )
        h[k] = v.to_f
      else
        h[k] = v
      end
      h
    end

    h
  end


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
