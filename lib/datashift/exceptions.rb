# Copyright:: (c) Autotelik Media Ltd 2014
# Author ::   Tom Statter
# Date ::     June 2014
# License::   Free, Open Source.
#

module DataShift

  class DataShiftException < StandardError
    require 'datashift/logging'
    #
    include DataShift::Logging

    def initialize( msg )
      super
      logger.error( msg)
    end
  end

  class SaveError < DataShiftException
    def initialize( msg )
      super( msg )
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

  class CreateAttachmentFailed < StandardError; end

end
