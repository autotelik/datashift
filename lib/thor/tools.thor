# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     Sept 2012
# License::   MIT.
#
# Usage::
#
#  To pull Datashift commands into your main application :
#
#     require 'datashift'
#
#     DataShift::load_commands
#
require 'datashift'
  
# Note, not DataShift, case sensitive, create namespace for command line : datashift
module Datashift        
  class Tools < Thor     
  
    include DataShift::Logging
      
    desc "zip", "Create zip of matching digital files" 

    method_option :path, :aliases => '-p', :required => true, :desc => "The path to the digital files"
    method_option :results, :aliases => '-r', :required => true, :desc => "The path to store resulting zip files"
 
    def zip()
     
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
      
      FileUtils::mkdir_p(output) unless File.exists?(output)
      
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

