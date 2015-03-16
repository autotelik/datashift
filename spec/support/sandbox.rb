


class Sandbox

  def add_gem(name, gem_options={})
    say_status :gemfile, name
    parts = ["'#{name}'"]
    parts << ["'#{gem_options.delete(:version)}'"] if gem_options[:version]
    gem_options.each { |key, value| parts << "#{key}: '#{value}'" }


    append_file 'Gemfile', "\ngem #{parts.join(', ')}", :verbose => false
  end

end