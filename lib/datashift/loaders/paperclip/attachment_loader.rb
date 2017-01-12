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

      attr_accessor :attach_to_klass, :attach_to_find_by_field, :attach_to_field

      # We try splitting up inbound file_names in various ways looking for the attachment Owner
      attr_accessor :split_file_name_on

      attr_reader :loading_files_cache, :missing_records

      def initialize
        super

        @attach_to_klass = nil
        @attach_to_find_by_field = nil
        @attach_to_field = nil

        @split_file_name_on = Regexp.new(/\s+/)

        @missing_records = []
      end

      # => :attach_to_klass
      #       A class that has a relationship with the attachment (has_many, has_one or belongs_to etc)
      #       The instance of :attach_to_klass can be searched for and the new attachment assigned.
      #
      #     Examples
      #       Owner has_many pdfs and mp3 files as Digitals .... :attach_to_klass = Owner
      #       User has a single image used as an avatar ... :attach_to_klass = User
      #
      # => :attach_to_find_by_field
      #       Field on the :attach_to_klass, this is the field used to search for the
      #       object (class == attach_to_klass) to assign the new attachment to.
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
      def init(attach_to_klass, attach_to_find_by_field, attach_to_field, options = {})

        @attach_to_klass = MapperUtils.ensure_class( attach_to_klass )

        ModelMethods::Manager.catalog_class(@attach_to_klass, reload: options[:reload], instance_methods: true)

        @attach_to_find_by_field = attach_to_find_by_field
        @attach_to_field = attach_to_field
      end

      def init_from_options(options)
        init(options[:attach_to_klass], options[:attach_to_find_by_field], options[:attach_to_field])

        @split_file_name_on = options[:split_file_name_on] if(options[:split_file_name_on])
      end

      def find_bindings
        # Map field to a suitable call on the Active Record Owner class e.g Owner.digitals
        bindings = begin
          logger.info("Finding matching field/association [#{attach_to_field}] on class [#{attach_to_klass}]")

          binder.map_inbound_fields(attach_to_klass, attach_to_field)
        rescue => e
          logger.error("Failed to map #{attach_to_field} to database operator : #{e.inspect}")
          logger.error( e.backtrace )
          raise MappingDefinitionError, 'Failed to map #{attach_to_field} to database operator'
        end

        bindings
      end

      def find_owner(in_file_name, options = {} )

        search_term = File.basename(in_file_name, '.*')
        search_term.strip!

        logger.info("Attempting to find attachment owner (#{attach_to_klass} for [#{search_term}]")

        owner_record = get_record_by(attach_to_klass, attach_to_find_by_field, search_term, split_file_name_on, options)

        if owner_record
          logger.info("#{owner_record.class} (id : #{owner_record.id}) found with matching :#{attach_to_find_by_field} ")
        else

          message = "No matching owner found for file name : #{search_term}"

          failed = FailureData.new(nil, doc_context.node_context, message)

          doc_context.progress_monitor.failure(failed)

          missing_records << in_file_name
        end

        owner_record
      end

      # This version creates attachments and also attaches them to instances of :attach_to_klazz
      #
      # Each file found in PATH will be processed - it's file_name being used to scan for
      # a matching record to attach the file to.
      #
      # Options
      #   :add_prefix
      #
      def perform_load(options = {} )

        raise 'The class that attachments belongs to has not been set (:attach_to_klass)' unless @attach_to_klass

        raise "The field to search for attachment's owner has not been set (:attach_to_find_by_field)" unless @attach_to_find_by_field

        is_dummy_run = DataShift::Configuration.call.dummy_run

        @missing_records = []

        @load_object = options[:attachment] if options[:attachment]

        # Support both directory and file
        @loading_files_cache = DataShift::Paperclip.get_files(file_name, options)

        logger.info("Found #{loading_files_cache.size} files - splitting names on delimiter [#{split_file_name_on}]")

        # Map field to a suitable call on the Active Record Owner class e.g Owner.digitals
        bindings = find_bindings

        attach_to_method_binding = if bindings.size != 1
                                     logger.warn("Failed to map #{attach_to_field} to database operator")
                                     nil
                                   else
                                     bindings[0]
                                   end

        # Iterate through all the files creating an attachment per file

        loading_files_cache.each do |in_file_name|
          attachment_name = File.basename(in_file_name)

          logger.info "Processing attachment file #{attachment_name} "

          owner_record = find_owner(in_file_name, options)

          # Don't actually create/upload to DB if we are doing dummy run
          # Don't create the Attachment if the Owner was not found

          next if(is_dummy_run || owner_record.nil?)

          attachment = create_paperclip_attachment(load_object_class, in_file_name, options)

          # Check if attachment must have an associated owner_record
          next unless attachment && owner_record && attach_to_method_binding
          reset

          # TOFIX - what about has_one etc ? - indicates that Context etc are still too complex and Excel/CSV focused
          owner_record.send(attach_to_method_binding.operator) << attachment

          logger.info "Added Attachment to #{owner_record.class} (id : #{owner_record.id})"
        end

        process_missing_records( missing_records )

        created = loading_files_cache.size - missing_records.size

        puts "Created #{created} / #{loading_files_cache.size} attachments of type #{load_object_class} attached to #{@attach_to_klass}"

        puts 'Dummy Run Complete - if happy run with full commit' if(is_dummy_run)

      end

    end

    def process_missing_records( missing_records )
      unless missing_records.empty?
        FileUtils.mkdir_p('MissingAttachmentRecords') unless File.directory?('MissingAttachmentRecords')

        puts "WARNING : #{missing_records.size} of #{loading_files_cache.size} files could not be attached to a #{load_object_class}"
        puts "For your convenience copying files with MISSING #{attach_to_klass} to : MissingAttachmentRecords"
        missing_records.each do |i|
          logger.info("Copying #{i} to MissingAttachmentRecords folder")
          FileUtils.cp( i, 'MissingAttachmentRecords') unless(DataShift::Configuration.call.dummy_run)
        end
      end
    end

  end
end
