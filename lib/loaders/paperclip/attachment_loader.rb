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
 
  class AttachmentLoader < LoaderBase
      
    include DataShift::Paperclip
      
    attr_accessor :attach_to_klass
      
    def initialize(attachment_klazz, attachment = nil, options = {})
        
      opts = options.merge(:load => false) 

      super( attachment_klazz, attachment, opts )
        
      @attach_to_klass  = options[:attach_to_klass]
           
      puts "Attachment Class is #{@attachment_klazz}" if(@verbose)
       
      @attachment = nil
      
      raise "Failed to create Attachment for loading" unless @load_object
    end
      
    # :attach_to_klazz
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

        # Check if attachment must have an associated record
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
