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
      logger.error(msg)
    end

    def self.generate(name)
      new_class = Class.new(DataShiftException) do
        def initialize( msg )
          super( msg )
        end
      end

      DataShift.const_set(name, new_class)
    end
  end

  # Non self logging errors

  class BadConfig < StandardError; end
  class BadFile < StandardError; end
  class BadRuby < StandardError; end
  class BadUri < StandardError; end

  class MappingDefinitionError < StandardError; end
  class MissingHeadersError < StandardError; end
  class MissingMandatoryError < StandardError; end

  class PathError < StandardError; end

  class RuntimeError < StandardError; end

  class UnsupportedFileType < StandardError; end
end

# Self logging errors

DataShift::DataShiftException.generate( 'BadOperatorType')
DataShift::DataShiftException.generate( 'ConfigFormatError')
DataShift::DataShiftException.generate( 'ConnectionError')
DataShift::DataShiftException.generate( 'CouldNotAssignAssociation')
DataShift::DataShiftException.generate( 'CouldNotDeriveAssociationClass')
DataShift::DataShiftException.generate( 'CreateAttachmentFailed')
DataShift::DataShiftException.generate( 'DataProcessingError')
DataShift::DataShiftException.generate( 'FileNotFound')
DataShift::DataShiftException.generate( 'NilDataSuppliedError')
DataShift::DataShiftException.generate( 'NoSuchClassError')
DataShift::DataShiftException.generate( 'NoSuchOperator')
DataShift::DataShiftException.generate( 'MissingConfigOptionError')
DataShift::DataShiftException.generate( 'RecordNotFound')
DataShift::DataShiftException.generate( 'SaveError')
DataShift::DataShiftException.generate( 'SourceIsNotAClass')
