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
    
    def create_attachment(klass, attachment_path, viewable_record = nil, options = {})
       
      has_attached_file = options[:has_attached_file_name].to_sym || :attachment
      

      file = get_file(attachment_path)

      begin
        
        attachment = klass.new( {has_attached_file => file, :viewable => viewable_record}, :without_protection => true)  
        
        #image.attachment.reprocess!  not sure this is required anymore
        
        puts attachment.save ? "Success: Created #{attachment.id} : #{attachment.attachment_file_name}" : "ERROR : Problem saving to DB : #{attachment.inspect}"
      rescue => e
        puts "PaperClip error - Problem creating Attachment from : #{attachment_path}"
        puts e.inspect, e.backtrace
      end
    end
    

    class AttachmentLoader < LoaderBase
      
      attr_accessor :attach_to_klazz
      
      def initialize(attachment_klazz, attachment = nil, options = {})
        
        opts = options.merge(:load => false)  # Don't need operators and no table Spree::Image

        super( attachment_klazz, attachment, opts )
        
        @attach_to_klazz  = options[:attach_to_klazz]
           
        puts "Attachment Class is #{@attachment_klazz}" if(@verbose)
          
        raise "Failed to create Attachment for loading" unless @load_object
      end
      
      # :split_file_name_on
      
      def process_from_filesystem(path, options )
       
        @attach_to_klazz  = options[:attach_to_klazz] if(options[:attach_to_klazz])
       
        raise "The class that attachments beloing to has not set" unless(@attach_to_klazz)
        
        @attachment_path = path
        
        missing_records = []
         
        # try splitting up filename in various ways looking for the SKU
        split_on = loader_config['split_file_name_on'] || options[:split_file_name_on]
             
        cache = Paperclip::get_files(@attachment_path, options)
      
        puts "Found #{cache.size} files - splitting names on delimiter : #{split_on}"
       
        attachment_field = options[:attach_to_field]
        
        cache.each do |name|

          attachment_name = File.basename(name)

          logger.info "Processing image file #{attachment_name} "
          
          base_name = File.basename(name, '.*')
          base_name.strip!
            
          record = nil
                   
          record = loader.get_record_by(@attach_to_klazz, attachment_field, base_name, split_on)
             
          if(record)
            logger.info "Found record for attachment : #{record.inspect}"
    
            if(options[:skip_when_assoc])
            
              paper_clip_name = attachment_name.gsub(Paperclip::Attachment::default_options[:restricted_characters], '_')
            
              exists = record.images.detect {|i| puts "Check #{paper_clip_name} matches #{i.attachment_file_name}"; i.attachment_file_name == paper_clip_name }
              if(exists)
                rid = record.respond_to?(:name) ? record.name : record.id
                puts "Skipping Image #{name} already loaded for #{rid}"
                logger.info "Skipping - Image #{name} already loaded for #{attachment_klazz}"
                next 
              end
            end
          else
            missing_records << name
          end
          
          next if(options[:dummy]) # Don't actually create/upload to DB if we are doing dummy run

          # Check if Image must have an associated record
          if(record || (record.nil? && options[:process_when_no_assoc]))
            loader.reset()
          
            logger.info("Adding Image #{name} to Product #{record.name}")
            loader.create_image(klazz, name, record)
            puts "Added Image #{File.basename(name)} to Product #{record.sku} : #{record.name}" if(@verbose)
          end

        end

        unless missing_records.empty?
          FileUtils.mkdir_p('MissingRecords') unless File.directory?('MissingRecords')
        
          puts "WARNING : #{missing_records.size} of #{cache.size} images could not be attached to a Product"
          puts 'For your convenience a copy of images with MISSING Products will be saved to :  ./MissingRecords'
          missing_records.each do |i|
            puts "Copying #{i} to MissingRecords folder" if(options[:verbose])
            FileUtils.cp( i, 'MissingRecords')  unless(options[:dummy] == 'true')
          end
        else
          puts "All images (#{cache.size}) were succesfully attached to a Product"
        end

        puts "Dummy Run Complete- if happy run without -d" if(options[:dummy])
   
      end
    
      def add_record(record)
        if(record)
          if(SpreeHelper::version.to_f > 1 )
            @load_object.viewable = record
          else
            @load_object.viewable = record.product   # SKU stored on Variant but we want it's master Product
          end
          @load_object.save
          puts "Image viewable set : #{record.inspect}"
          
        else
          puts "WARNING - Cannot set viewable - No matching record supplied"
          logger.error"Failed to find a matching record"
        end
      end
    end
    
  end
      
end
