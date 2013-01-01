module DataShift

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