# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     Sept 2012
# License::   MIT. Free, Open Source.
#
# => Provides facilities for bulk uploading/exporting attachments provided by PaperClip gem
#
require 'loader_base'

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
    

    class AttachmentLoader < LoaderBase
      
      include DataShift::Paperclip
      
      attr_accessor :attach_to_klass
      
      def initialize(attachment_klazz, attachment = nil, options = {})
        
        opts = options.merge(:load => false)  # Don't need operators and no table Spree::Image

        super( attachment_klazz, attachment, opts )
        
        @attach_to_klass  = options[:attach_to_klass]
           
        puts "Attachment Class is #{@attachment_klazz}" if(@verbose)
          
        raise "Failed to create Attachment for loading" unless @load_object
      end
      
      # :split_file_name_on
      
      def process_from_filesystem(path, options )
       
        @attach_to_klass  = options[:attach_to_klazz] if(options[:attach_to_klazz])
       
        raise "The class that attachments belong to has not set" unless(@attach_to_klass)
        
        @attachment_path = path
        
        missing_records = []
         
        # try splitting up filename in various ways looking for the SKU
        split_search_term  = @config['split_file_name_on'] || options[:split_file_name_on]
             
        cache = Paperclip::get_files(@attachment_path, options)
      
        puts "Found #{cache.size} files - splitting names on delimiter [#{split_search_term}]"
       
        lookup_field = options[:attach_to_lookup_field]
        
        cache.each do |file_name|

          attachment_name = File.basename(file_name)

          logger.info "Processing attachment file #{attachment_name} "
          
          base_name = File.basename(file_name, '.*')
          base_name.strip!
            
          record = nil
                   
          record = get_record_by(@attach_to_klass, lookup_field, base_name, split_search_term)
             
          if(record)
            logger.info "Found record for attachment : #{record.inspect}"
          else
            missing_records << file_name
          end
          
          next if(options[:dummy]) # Don't actually create/upload to DB if we are doing dummy run

          # Check if Image must have an associated record
          if(record)
            reset()
          
            create_attachment(@load_object_class, file_name, record, options[:attach_to_klass_field], options)
   
            puts "Added Attachment #{File.basename(file_name)} to #{record.send(lookup_field)} : #{record.id}" if(@verbose)
          end

        end

        unless missing_records.empty?
          FileUtils.mkdir_p('MissingAttachmentRecords') unless File.directory?('MissingAttachmentRecords')
        
          puts "WARNING : #{missing_records.size} of #{cache.size} files could not be attached to a #{@load_object_class}"
          puts "For your convenience a copy of files with MISSING #{@load_object_class} :  ./MissingAttachmentRecords"
          missing_records.each do |i|
            puts "Copying #{i} to MissingAttachmentRecords folder" if(options[:verbose])
            FileUtils.cp( i, 'MissingAttachmentRecords')  unless(options[:dummy] == 'true')
          end
        else
          puts "All files (#{cache.size}) were succesfully attached to a #{@load_object_class}"
        end

        puts "Dummy Run Complete- if happy run without -d" if(options[:dummy])
   
      end
   
    end
    
  end
      
end
