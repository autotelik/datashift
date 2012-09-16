# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     Sept 2012
# License::   MIT. Free, Open Source.
#
# Details::   Module containing common functionality for working with Paperclip attachments
# 
require 'logging'

module DataShift

  module Paperclip
    
    include DataShift::Logging
    
    # Get all image files (based on file extensions) from supplied path.
    # Options : 
    #     :glob : The glob to use to find files
    # =>  :recursive : Descend tree looking for files rather than just supplied path
    
    def self.get_files(path, options = {})
      glob = options[:glob] ? options[:glob] : '*.*'
      glob = (options['recursive'] || options[:recursive])  ? "**/#{glob}" : glob
      
      Dir.glob("#{path}/#{glob}", File::FNM_CASEFOLD)
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
    #   has_attached_file_name : Paperclip attachment name defined with macro 'has_attached_file :name'  
    #     e.g 
    #     has_attached_file :avatar =>  options[:has_attached_file_name] = :avatar
    #     has_attached_file :icon   =>  options[:has_attached_file_name] = :icon
    #
    #   alt : Alternatice text for images
    
    def create_attachment(klass, attachment_path, record = nil, attach_to_record_field = nil, options = {})
       
      has_attached_file = options[:has_attached_file_name] ? options[:has_attached_file_name].to_sym : :attachment
      
      file = get_file(attachment_path)

      begin
        
        attachment = if(record && attach_to_record_field)
          klass.new( {has_attached_file => file}, :without_protection => true)  
        else
          klass.new( {has_attached_file => file, attach_to_record_field.to_sym => record}, :without_protection => true)  
        end
        puts attachment.save ? "Success: Created #{attachment.id} : #{attachment.attachment_file_name}" : "ERROR : Problem saving to DB : #{attachment.inspect}"
      rescue => e
        puts "PaperClip error - Problem creating Attachment from : #{attachment_path}"
        puts e.inspect, e.backtrace
      end
    end
    
  end
  
  
end
