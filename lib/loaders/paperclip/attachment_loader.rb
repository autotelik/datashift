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
      
      attr_writer :attach_to_field
      attr_reader :attachment_path, :loading_files_cache

      
      # Constructor
      # 
      # Options 
      #
      # => :attach_to_klass    
      #       A class that has a relationship with the attachment (has_many, has_one or belongs_to etc)  
      #       The instance of :attach_to_klass can be searched for and the new attachment assigned.
      #       
      #     Examples     
      #       Owner has_many pdfs and mp3 files as Digitals .... :attach_to_klass = Owner
      #       User has a single image used as an avatar ... :attach_to_klass = User
      #
      # => :attach_to_find_by_field    
      #       For the :attach_to_klass, this is the field used to search for the parent
      #       object to assign the new attachment to.
      #       
      #     Examples     
      #       Owner has a unique 'name' field ... :attach_to_find_by_field = :name
      #       User has a unique  'login' field  ... :attach_to_klass = :login
      #
      # => :attach_to_field    
      #       Attribute/association to assign attachment to on :attach_to_klass.
      #      Examples
      #      
      #         :attach_to_field => digitals  : Owner.digitals = attachment
      #         :attach_to_field => avatar    : User.avatar = attachment
      #         
      #       
      def initialize(attachment_klazz, attachment = nil, options = {})
        
        init_from_options( options )
 
        super( attachment_klazz, attachment, options.dup )
         
        puts "Attachment Class is #{load_object_class}" if(@verbose)
       
        raise "Failed to create Attachment for loading" unless @load_object
      end
            
      
      # Options
      # :reload
      # :attach_to_klass, :attach_to_field, :attach_to_find_by_field
      #
      def init_from_options( options )
        
        @attach_to_klass  = options[:attach_to_klass] || @attach_to_klass || nil
            
        unless(@attach_to_klass.nil? || (MethodDictionary::for?(@attach_to_klass) && options[:reload] == false))
          #puts "Building Method Dictionary for class #{object_class}"
          DataShift::MethodDictionary.find_operators( @attach_to_klass, :reload => options[:reload], :instance_methods => true )
        
          # Create dictionary of data on all possible 'setter' methods which can be used to
          # populate or integrate an object of type @load_object_class
          DataShift::MethodDictionary.build_method_details(@attach_to_klass)
        end
      
        @attach_to_find_by_field  = options[:attach_to_find_by_field] || @attach_to_find_by_field || nil
        @attach_to_field  = options[:attach_to_field] || @attach_to_field || nil
        
        unless(@attach_to_klass.nil? && @attach_to_field.nil? )
          @attach_to_method_detail = MethodDictionary.find_method_detail(@attach_to_klass, @attach_to_field)
        end
      end
      
            
      # If we have instantiated a method detail based on the attach to class and fields
      # return that otherwise return the raw format of :attach_to_find_by_field
      
      def attach_to_field
        @attach_to_method_detail || @attach_to_field
      end
      
      
      # This version creates attachments and also attaches them to instances of :attach_to_klazz
      # 
      # Each file found in PATH will be processed - it's filename being used to scan for
      # a matching record to attach the file to.
      # 
      # Options
      #   :split_file_name_on   Used in scan process to progresivly split filename to find   
      #                         :attach_to_klass with matching :attach_to_find_by_field
      #
      #   :add_prefix
      #
      def process_from_filesystem(path, options = {} )
     
        init_from_options( options )
        
        raise "The class that attachments belongs to has not been set (:attach_to_klass)" unless(@attach_to_klass) 
                
        raise "The field to search for attachment's owner has not been set (:attach_to_find_by_field)" unless(@attach_to_find_by_field)
               
        @load_object = options[:attachment] if(options[:attachment])
  
        @attachment_path = path
        
        missing_records = []
         
        # try splitting up filename in various ways looking for the attachment owqner
        split_on  = @config['split_file_name_on'] || options[:split_file_name_on]
             
        @loading_files_cache = DataShift::Paperclip::get_files(path, options)
      
        puts "Found #{loading_files_cache.size} files - splitting names on delimiter [#{split_on}]"

        loading_files_cache.each do |file_name|

          attachment_name = File.basename(file_name)

          logger.info "Processing attachment file #{attachment_name} "
          
          base_name = File.basename(file_name, '.*')
          base_name.strip!
            
          record = nil
            
          puts "Attempting fo find Record for file name : #{base_name}"
          record = get_record_by(attach_to_klass, attach_to_find_by_field, base_name, split_on, options)
             
          if(record)
            puts "Found #{record.class} where : #{attach_to_find_by_field} = #{record.send(attach_to_find_by_field)}(id : #{record.id})"
          else
            missing_records << file_name
          end
          
          next if(options[:dummy]) # Don't actually create/upload to DB if we are doing dummy run

          # Check if attachment must have an associated record
          if(record)
            reset()

            create_paperclip_attachment(@load_object_class, file_name, record, attach_to_field, options)
   
            puts "Added Attachment #{File.basename(file_name)} to #{record.send(attach_to_find_by_field)}(id : #{record.id})" if(@verbose)
          end

        end

        unless missing_records.empty?
          FileUtils.mkdir_p('MissingAttachmentRecords') unless File.directory?('MissingAttachmentRecords')
        
          puts "WARNING : #{missing_records.size} of #{loading_files_cache.size} files could not be attached to a #{@load_object_class}"
          puts "For your convenience copying files with MISSING #{attach_to_klass} to : MissingAttachmentRecords"
          missing_records.each do |i| 
            FileUtils.cp( i, 'MissingAttachmentRecords')  unless(options[:dummy] == 'true')
            puts "Copyied #{i} to MissingAttachmentRecords folder" if(options[:verbose])
          end
        end

        puts "Created #{loading_files_cache.size - missing_records.size} of #{loading_files_cache.size} #{@load_object_class} attachments and succesfully attached to a #{@attach_to_klass}"
         
        puts "Dummy Run Complete- if happy run without -d" if(options[:dummy])
   
      end
   
    end
      
  end
end