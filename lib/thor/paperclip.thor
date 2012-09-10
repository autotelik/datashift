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
#     thor help datashift:paperclip:attach
#
require 'datashift'

# Note, not DataShift, case sensitive, create namespace for command line : datashift
module Datashift
         
  class Paperclip < Thor     
  
    include DataShift::Logging   

    desc "attach", "Attach files from a directory\nwhere file names contain somewhere the lookup info"
    
    # :dummy => dummy run without actual saving to DB
    method_option :input, :aliases => '-i', :required => true, :desc => "The input path containing images "
    
    method_option :glob, :aliases => '-g',  :desc => 'The glob to use to find files e.g. \'{*.jpg,*.gif,*.png}\' '
    method_option :recursive, :aliases => '-r', :type => :boolean, :desc => "Scan sub directories of input for images"
     
    method_option :attachment_klass, :required => true, :aliases => '-a', :desc => "Ruby Class name of the Attachment e.g Image, Icon"
    method_option :attach_to_klass, :required => true, :aliases => '-k', :desc => "Ruby Class name attachment belongs to e.g Product, Blog"
    method_option :attach_to_klass_field, :required => true, :aliases => '-f', :desc => "Attachment belongs to field e.g Product.image, Blog.digital"
    
    method_option :attach_to_lookup_field, :required => true, :aliases => '-l', :desc => "The field to use to find the :attach_to_klass record"
    
    method_option :split_file_name_on,  :type => :string, :desc => "delimiter to progressivley split filename for lookup", :default => ' '
    method_option :case_sensitive, :type => :boolean, :desc => "Use case sensitive where clause to find :attach_to_klass"
    method_option :use_like, :type => :boolean, :desc => "Use :lookup_field LIKE 'string%' instead of :lookup_field = 'string' in where clauses to find :attach_to_klass"
  
    method_option :dummy, :aliases => '-d', :type => :boolean, :desc => "Dummy run, do not actually save attachment"
       
    method_option :skip_when_assoc, :aliases => '-x', :type => :boolean, :desc => "Do not process if :attach_to_klass already has an attachment"
    
    method_option :verbose, :aliases => '-v', :type => :boolean, :desc => "Verbose logging"

    def attach()

      @attachment_path = options[:input]
      
      unless(File.exists?(@attachment_path))
        puts "ERROR: Supplied Path [#{@attachment_path}] not accesible"
        exit(-1)
      end
      
      require File.expand_path('config/environment.rb')
      
      require 'paperclip/attachment_loader'
            
      @verbose = options[:verbose]

      puts "Using Field #{options[:attach_to_field]} for lookup"
       
      klazz = ModelMapper::class_from_string( options[:attachment_klass] )     
      raise "Cannot find Attachment Class #{options[:attachment_klass]}" unless klazz
       
      attachment_klazz  = ModelMapper::class_from_string( options[:attach_to_klass] )
      raise "Cannot find Attach to Class #{options[:attach_to_klass]}" unless klazz
      
      opts = options.dup
      
      opts[:attach_to_klass] = attachment_klazz # Pass in real Ruby class not string class name
      
      loader = DataShift::Paperclip::AttachmentLoader.new(klazz, nil, opts)
   
      logger.info "Loading attachments from #{@attachment_path}"

      loader.process_from_filesystem(@attachment_path, opts)
    
    end
  end
  
end
