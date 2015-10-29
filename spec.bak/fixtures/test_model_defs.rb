

base = File.join(File.dirname(__FILE__), 'models')

Dir[ File.join(base, '*.rb') ].each do |file|
  require File.join(base, File.basename(file, File.extname(file) ))
end
