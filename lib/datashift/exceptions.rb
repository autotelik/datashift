# Copyright:: (c) Autotelik Media Ltd 2014 
# Author ::   Tom Statter
# Date ::     June 2014
# License::   Free, Open Source.
#

module DataShift
  
  class DataShiftException < StandardError

    include DataShift::Logging
        
    def initialize( msg )
      super
      logger.error( msg)
    end

    def self.generate name
      new_class = Class.new(DataShiftException) do
        def initialize( msg )
          super( msg )
        end
      end

      DataShift.const_set(name, new_class)
    end
  end

  class NilDataSuppliedError  < DataShiftException
    def initialize( msg )
      super( msg )
    end
  end
  
  class BadRuby < StandardError; end
  
  class UnsupportedFileType < StandardError; end
  class BadFile < StandardError; end
  
  class MappingDefinitionError < StandardError; end
  class DataProcessingError < StandardError; end

  class MissingHeadersError < StandardError; end
  class MissingMandatoryError < StandardError; end

  class RecordNotFound < StandardError; end
  
  class PathError < StandardError; end
  
  class BadUri < StandardError; end

end


DataShift::DataShiftException.generate( "ConnectionError")
DataShift::DataShiftException.generate( "CouldNotAssignAssociation")
DataShift::DataShiftException.generate( "CreateAttachmentFailed")
DataShift::DataShiftException.generate( "FileNotFound")
DataShift::DataShiftException.generate( "NoSuchClassError")
DataShift::DataShiftException.generate( "MissingConfigOptionError")
DataShift::DataShiftException.generate( "SaveError")