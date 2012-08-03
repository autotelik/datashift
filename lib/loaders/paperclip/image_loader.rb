# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     June 2012
# License::   MIT. Free, Open Source.
#
# => Provides facilities for bulk uploading/exporting attachments provided by PaperClip 
# gem
require 'loader_base'

module DataShift

  module ImageLoading
 
    include DataShift::Logging
    
    def self.get_files(path, options = {})
      glob = (options['recursive'] || options[:recursive])  ? "**/*.{jpg,jpeg,png,gif}" : "*.{jpg,jpeg,png,gif}"
      
      Dir.glob("#{path}/#{glob}")
    end
  
    def get_file( attachment_path )
      
      unless File.exists?(attachment_path) && File.readable?(attachment_path)
        logger.error("Cannot process Image from #{Dir.pwd}: Invalid Path #{attachment_path}")
        raise "Cannot process Image : Invalid Path #{attachment_path}"
      end
     
      file = begin
        File.new(attachment_path, "rb")
      rescue => e
        puts e.inspect
        raise "ERROR : Failed to read image #{attachment_path}"
      end
      
      file
    end
    
    # Note the paperclip attachment model defines the storage path via something like :
    # => :path => ":rails_root/public/blah/blahs/:id/:style/:basename.:extension"
    # Options 
    #   has_attached_file_name : Paperclip attachment name defined with macro 'has_attached_file :name'  e.g has_attached_file :avatar
    #
    def create_image(klass, attachment_path, viewable_record = nil, options = {})
       
      has_attached_file = options[:has_attached_file_name] || :attachment
      
      alt = if(options[:alt])
        options[:alt]
      else
        (viewable_record and viewable_record.respond_to? :name) ? viewable_record.name : ""
      end
    
      position = (viewable_record and viewable_record.respond_to?(:images)) ? viewable_record.images.length : 0
          
      file = get_file(attachment_path)

      begin
        
        image = klass.new( 
          {has_attached_file.to_sym => file, :viewable => viewable_record, :alt => alt, :position => position},
          :without_protection => true
        )  
        
        #image.attachment.reprocess!  not sure this is required anymore
        
        puts image.save ? "Success: Created Image: #{image.id} : #{image.attachment_file_name}" : "ERROR : Problem saving to DB Image: #{image.inspect}"
      rescue => e
        puts "PaperClip error - Problem creating an Image from : #{attachment_path}"
        puts e.inspect, e.backtrace
      end
    end
  end
      
end
