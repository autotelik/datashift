class String

  # Convert DSL string forms into a hash
  # e.g
  #
  #  "{:name => 'autechre'}" =>   Hash['name'] = autechre'
  #  "{:cost_price => '13.45', :price => 23,  :sale_price => 4.23 }"
  #  "{:cost_price => '13.45', :price => 23,  :sale_price => 4.23 }"

  def to_hash_object

    h = {}

    self.gsub(/[{}]/,'').split(',').each do |e|
      e.strip!

      k,v = if(e.include?('=>'))
              e.split('=>')
            else
              e.split(': ')
            end

      k = k.gsub(/[:']/,'').strip  # easier to treat all keys as strings
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

end