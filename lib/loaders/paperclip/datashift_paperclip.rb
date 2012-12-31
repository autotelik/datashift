# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     Sept 2012
# License::   MIT. Free, Open Source.
#
# Details::   Module containing common functionality for working with Paperclip attachments
# 
require 'logging'
require 'paperclip'

module DataShift

  module Paperclip
    
    include DataShift::Logging
    include DataShift::Logging
    require 'paperclip/attachment_loader'
    
    attr_accessor :attachment
    
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
        raise PathError.new("Cannot process Image : Invalid Path #{attachment_path}")
      end
     
      file = begin
        File.new(attachment_path, "rb")
      rescue => e
        puts e.inspect
        raise PathError.new("ERROR : Failed to read image from #{attachment_path}")
      end
      
      file
    end
    
    # Note the paperclip attachment model defines the storage path via something like :
    # => :path => ":rails_root/public/blah/blahs/:id/:style/:basename.:extension"
    # 
    # Options 
    # 
    #   :attributes
    #     
    #     Pass through hash of attributes to klass initializer
    # 
    #   :has_attached_file_name
    #   
    #     Paperclip attachment name defined with macro 'has_attached_file :name'  
    #   
    #     e.g 
    #       When : has_attached_file :avatar 
    #      
    #       Give : {:has_attached_file_attribute => :avatar}
    #       
    #       When :  has_attached_file :icon 
    #
    #       Give : { :has_attached_file_attribute => :icon }
    #     
    def create_attachment(klass, attachment_path, record = nil, attach_to_record_field = nil, options = {})
       
      has_attached_file_attribute = options[:has_attached_file_name] ? options[:has_attached_file_name].to_sym : :attachment
  
      # e.g  (:attachment => File.read) - TODO investigate this File handle .. does it need closing ?
      attributes = { has_attached_file_attribute => get_file(attachment_path) }
     
      attributes.merge!(options[:attributes]) if(options[:attributes])

      # DEBUG puts attributes.inspect
      
      begin
        
        @attachment = klass.new(attributes, :without_protection => true) 
      
        if(@attachment.save)
          puts "Success: Created Attachment #{@attachment.id} : #{@attachment.attachment_file_name}"
                
          if(attach_to_record_field.is_a? MethodDetail)
            attach_to_record_field.assign(record, @attachment)
          else
            # assume its not a has_many and try basic send 
            record.send("#{attach_to_record_field}=", @attachment)
          end if(record && attach_to_record_field)
          
        else
          puts "ERROR : Problem saving to DB : #{@attachment.inspect}"
          puts @attachment.errors.messages.inspect
        end
        
        @attachment
      rescue => e
        puts "PaperClip error - Problem creating Attachment from : #{attachment_path}"
        puts e.inspect, e.backtrace
      end
    end
    
  end
  
  
end
