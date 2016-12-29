# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     March 2016
# License::   MIT.
#
# Usage::
#
#     thor help datashift:paperclip:attach
#
require 'thor'
require_relative 'thor_behaviour'

# Note, not DataShift, case sensitive, create namespace for command line : datashift
module Datashift
         
  class Paperclip < Thor

    include DataShift::ThorBehavior

    desc "attach", "Create paperclip attachments and attach to a Model from files in a directory.
    This is specifically for the use case where the paperclip attachments are stored in a class, such as Image, Icon, Asset,
    and this class has a relationship, such as belongs_to, with another class, such as Product, User, Document.
 
    Each matching file is used to create an instance of the paperclip attachment, given by :attachment_klass.
    
    The class with the relationship, can be specified via :attach_to_klass

      Examples     
        Owner has_many pdfs and mp3 files as Digitals .... :attachment_klass = Digital and :attach_to_klass = Owner
        User has a single Image used as an avatar ... attachment_klass = Image and :attach_to_klass = User
    
    The file name is used to lookup the instance of :attach_to_klass to assign the new attachment to, via :attach_to_find_by_field

    So say we have a file called smithj_avatar.gif, and we want to lookup Users by login

        :attach_to_find_by_field = login => Run a loookup based on find_by_login == 'smithj'

    Once instance of :attach_to_klass found, the new attachment is assigned.

     The attribute to assign new attachment to is gtiven by :attach_to_field    
  
     Examples
        :attach_to_field => digitals  : Owner.digitals = attachment(Digital)
        :attach_to_field => avatar    : User.avatar = attachment(Image)"
    

    # :dummy => dummy run without actual saving to DB
    method_option :input, :aliases => '-i', :required => true, :desc => "The input path containing images "
    
    method_option :glob, :aliases => '-g',  :desc => 'The glob to use to find files e.g. \'{*.jpg,*.gif,*.png}\' '
    method_option :recursive, :aliases => '-r', :type => :boolean, :desc => "Scan sub directories of input for images"
     
    method_option :attachment_klass, :required => true, :aliases => '-a', :desc => "Ruby Class name of the Attachment e.g Image, Icon"
    
    method_option :attach_to_klass, :required => true, :aliases => '-k', :desc => "A class that has a relationship with the attachment (has_many, has_one, belongs_to)"     
    method_option :attach_to_find_by_field, :required => true, :aliases => '-l', :desc => "The field to use to find the :attach_to_klass record"
    method_option :attach_to_field, :required => true, :aliases => '-f', :desc => "Attachment belongs to field e.g Product.image, Blog.digital"
  
    
      # => :attach_to_find_by_field    
      #       For the :attach_to_klass, this is the field used to search for the parent
      #       object to assign the new attachment to.
      #     Examples     
      #       Owner has a unique 'name' field ... :attach_to_find_by_field = :name
      #       User has a unique  'login' field  ... :attach_to_klass = :login
      #
      # => :attach_to_field    
      #       Attribute/association to assign attachment to on :attach_to_klass.
      #      Examples
      #         :attach_to_field => digitals  : Owner.digitals = attachment
      #         :attach_to_field => avatar    : User.avatar = attachment
      
    method_option :split_file_name_on,  :type => :string,
                  :desc => "delimiter to progressivley split file_name for lookup", :default => ' '

    method_option :case_sensitive, :type => :boolean, :desc => "Use case sensitive where clause to find :attach_to_klass"
    method_option :use_like, :type => :boolean, :desc => "Use :lookup_field LIKE 'string%' instead of :lookup_field = 'string' in where clauses to find :attach_to_klass"

    method_option :skip_when_assoc, :aliases => '-x', :type => :boolean, :desc => "Do not process if :attach_to_klass already has an attachment"
    
    method_option :verbose, :aliases => '-v', :type => :boolean, :desc => "Verbose logging"

    def attach()

      @attachment_path = options[:input]
      
      unless(File.exist?(@attachment_path))
        puts "ERROR: Supplied Path [#{@attachment_path}] not accesible"
        exit(-1)
      end

      start_connections
      
      require 'paperclip/attachment_loader'

      puts "Using Field #{options[:attach_to_find_by_field]} to lookup matching [#{options[:attach_to_klass]}]"

      loader = DataShift::Paperclip::AttachmentLoader.new

      loader.init_from_options(options)

      logger.info "Loading attachments from #{@attachment_path}"

      loader.run(@attachment_path, options[:attachment_klass])
    end
  end
  
end
