# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specific loader to support Excel files.
#             Note this only requires JRuby, Excel not required, nor Win OLE.
#
#             Maps column headings to operations on the model.
#             Iterates over all the rows using mapped operations to assign row data to a database object,
#             i.e pulls data from each column and sends to object.
#
module DataShift

  class ExcelLoader < LoaderBase

    include ExcelLoading

    # Setup loading
    #
    # Options to drive building the method dictionary for a class, enabling headers to be mapped to operators on that class.
    #
    # Options
    #  :reload           : Force load of the method dictionary for object_class even if already loaded
    #  :instance_methods : Include setter/delegate style instance methods for assignment, as well as AR columns
    #  :verbose          : Verbose logging and to STDOUT
    #
    def initialize(klass, object = nil, options = {})
      super( klass, object, options )
      raise "Cannot load - failed to create a #{klass}" unless(load_object)
    end


    def perform_load( file_name, options = {} )

      logger.info "Starting bulk load from Excel : #{file_name}"

      perform_excel_load( file_name, options )

      puts "Excel loading stage complete - #{loaded_count} rows added."
    end

  end
end