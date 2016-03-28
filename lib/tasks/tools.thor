# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     April 2016
# License::   MIT.
#
#
require 'datashift'
  
# Note, not DataShift, case sensitive, create namespace for command line : datashift
module Datashift

  class Tools < Thor     
  
    include DataShift::Logging

    desc 'file_rename', 'Clone a folder of files, consistently renaming each in the process'

    method_option :path, :aliases => '-p', required: true, desc: "The path to the original files"
    method_option :output, :aliases => '-o', required: true, desc: "The resulting zip file name"
    method_option :offset,  required: false, type: :numeric, desc: "A numeric offset to add to the file name"
    method_option :width,  required: false, type: :numeric, desc: "A numeric width tp pad the file name"
    method_option :prefix,  required: false, desc: "A strign prefix to add to file name"
    method_option :commit,  required: false, type: :boolean, desc: "Actually perform copy"

    def file_rename

      cache = options[:path]

      if File.exist?(cache)
        puts "Renaming files from #{cache}"
        Dir.glob(File.join(cache, '*')) do |name|
          path, base_name = File.split(name)
          id = base_name.slice!(/\w+/)

          id = id.to_i + options[:offset].to_i if options[:offset]
          id = "%0#{width}d" % id.to_i if options[:width]
          id = options[:prefix] + id.to_s if options[:prefix]

          destination = File.join( options[:output], "#{id}#{base_name}")
          puts "File Rename: cp #{name} #{destination}"

          File.send( 'cp', name, destination) if options[:commit]
        end
      end
    end

    desc "zip", "Create zip of files" 

    method_option :path, :aliases => '-p', required: true, desc: "The path to the digital files"
    method_option :output, :aliases => '-o', required: true, desc: "The resulting zip file name"
 
    def zip
     
      require 'zip/zip'
      require 'zip/zipfilesystem'

      output = options[:output]

      Zip::ZipOutputStream.open(output) do |zos|
        Dir[File.join(options[:path], '**', '*.*')].each do |p|
          zos.put_next_entry(File.basename(p))
          zos.print IO.read(p)
        end
      end
    end
    
    desc "zip_matching", "Create zip of matching digital files e.g zip up pdf, jpg and png versions of a file" 

    method_option :path, :aliases => '-p', required: true, desc: "The path to the digital files"
    method_option :results, :aliases => '-r', required: true, desc: "The path to store resulting zip files"
 
    def zip_matching()
     
      require 'zip/zip'
      require 'zip/zipfilesystem'

      ready_to_zip = {}
      Dir[File.join(options[:path], '**', '*.*')].each do |p|
        next if File.directory? p
        
        basename = File.basename(p, '.*')
        ready_to_zip[basename] ||= []       
        ready_to_zip[basename] << p  
      end 
      
      output = options[:results]
      
      FileUtils::mkdir_p(output) unless File.exist?(output)
      
      puts "Creating #{ready_to_zip.keys.size} new zips"
      ready_to_zip.each do |basename, paths|
      
        z= File.join(output, basename + '.zip')
        puts "zipping to #{z}"
        
        Zip::ZipOutputStream.open(z) do |zos|
          paths.each do |file|
            zos.put_next_entry(File.basename(file))
            zos.print IO.read(file)
          end
        end
      end
      
    end   
    
  end

end

