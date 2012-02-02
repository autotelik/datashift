# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Feb 2011
# License::   MIT
#
# Usage::     rake datashift:file_rename input=/blah image_load input=path_to_images
#
namespace :datashift do

  desc "copy or mv a folder of files, consistently renaming in the process"
  task :file_rename, :input, :offset, :prefix, :width, :commit, :mv do |t, args|
    raise "USAGE: rake file_rename input='C:\blah' [offset=n prefix='str' width=n]" unless args[:input] && File.exists?(args[:input])
    width = args[:width] || 2

    action = args[:mv] ? 'mv' : 'cp'

    cache = args[:input]

    if(File.exists?(cache) )
      puts "Renaming files from #{cache}"
      Dir.glob(File.join(cache, "*")) do |name|
        path, base_name = File.split(name)
        id = base_name.slice!(/\w+/)

        id = id.to_i + args[:offset].to_i if(args[:offset])
        id = "%0#{width}d" % id.to_i if(args[:width])
        id = args[:prefix] + id.to_s if(args[:prefix])

        destination = File.join(path, "#{id}#{base_name}")
        puts "ACTION: #{action} #{name} #{destination}"

        File.send( action, name, destination) if args[:commit]
      end
    end
  end

end