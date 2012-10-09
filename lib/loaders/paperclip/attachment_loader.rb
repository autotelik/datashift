# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     Sept 2012
# License::   MIT. Free, Open Source.
#
# => Provides facilities for bulk uploading/exporting attachments provided by PaperClip gem
#
require 'loader_base'
require 'datashift_paperclip'

module DataShift
 
  module Paperclip
    
    class AttachmentLoader < LoaderBase
      
      include DataShift::Paperclip
      
      attr_accessor :attach_to_klass, :attach_to_find_by_field
      
      attr_reader :attachment_path, :loading_files_cache
      
      # Options 
    
      # => :attach_to_klass    
      #       A class that has a relationship with - has_many, has_one or belongs_to - the attachment 
      #       The instance of :attach_to_klass can be searched for and the new attachment assigned.
      #
      # => :attach_to_find_by_field    
      #       For the :attach_to_klass, this is the field to use to searched for object to assign the new attachment to.
      
      def initialize(attachment_klazz, attachment = nil, options = {})
        
        @attach_to_klass  = options[:attach_to_klass] || NilClass
        @attach_to_find_by_field  = options[:attach_to_find_by_field] || nil
                
        @attachment = attachment

        opts = options.merge(:load => false) 

        super( attachment_klazz, attachment, opts )
         
        puts "Attachment Class is #{load_object_class}" if(@verbose)
 
      
        raise "Failed to create Attachment for loading" unless @load_object
      end
      
      # This version creates attachments and also attaches them to instances of :attach_to_klazz
      # 
      # Options
      #   :split_file_name_on   Used in scan process to progresivly split filename to find   
      #                         :attach_to_klass with matching :attach_to_find_by_field
      #
      #
      def process_from_filesystem(path, options )
     
        @attachment = options[:attachment] if(options[:attachment])
        
        @attach_to_klass  = options[:attach_to_klazz] if(options[:attach_to_klazz])
       
        raise "The class that attachments belong to has not been set" unless(@attach_to_klass || @attachment) 
               
        @attach_to_find_by_field = options[:attach_to_find_by_field] if(options[:attach_to_find_by_field])
        
        raise "The field to search for attachment's owner has not been set (:attach_to_find_by_field)" unless(@attach_to_find_by_field || @attachment)
        
        @attachment_path = path
        
        missing_records = []
         
        # try splitting up filename in various ways looking for the attachment owqner
        split_on  = @config['split_file_name_on'] || options[:split_file_name_on]
             
        @loading_files_cache = Paperclip::get_files(path, options)
      
        puts "Found #{loading_files_cache.size} files - splitting names on delimiter [#{split_on}]"

        loading_files_cache.each do |file_name|

          attachment_name = File.basename(file_name)

          logger.info "Processing attachment file #{attachment_name} "
          
          base_name = File.basename(file_name, '.*')
          base_name.strip!
            
          record = nil
            
          puts "try to find record where #{attach_to_find_by_field} ==  #{base_name}"
          record = get_record_by(attach_to_klass, attach_to_find_by_field, base_name, split_on)
             
          if(record)
            puts "Found record for attachment : #{record.inspect}"
            logger.info "Found record for attachment : #{record.inspect}"
          else
            missing_records << file_name
          end
          
          next if(options[:dummy]) # Don't actually create/upload to DB if we are doing dummy run

          # Check if attachment must have an associated record
          if(record)
            puts "now create attachment"
            reset()
          
            create_attachment(@load_object_class, file_name, record, attach_to_field, options)
   
            puts "Added Attachment #{File.basename(file_name)} to #{record.send(attach_to_find_by_field)} : #{record.id}" if(@verbose)
          end

        end

        unless missing_records.empty?
          FileUtils.mkdir_p('MissingAttachmentRecords') unless File.directory?('MissingAttachmentRecords')
        
          puts "WARNING : #{missing_records.size} of #{loading_files_cache.size} files could not be attached to a #{@load_object_class}"
          puts "For your convenience a copy of files with MISSING #{@load_object_class} :  ./MissingAttachmentRecords"
          missing_records.each do |i|
            puts "Copying #{i} to MissingAttachmentRecords folder" if(options[:verbose])
            FileUtils.cp( i, 'MissingAttachmentRecords')  unless(options[:dummy] == 'true')
          end
        else
          puts "All files (#{loading_files_cache.size}) were succesfully attached to a #{@load_object_class}"
        end

        puts "Dummy Run Complete- if happy run without -d" if(options[:dummy])
   
      end
   
    end
      
  end
end