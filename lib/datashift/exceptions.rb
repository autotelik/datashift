module DataShift

  class BadRuby < StandardError; end
  
  class UnsupportedFileType < StandardError; end
  
  class MappingDefinitionError < StandardError; end

  class MissingHeadersError < StandardError; end
  class MissingMandatoryError < StandardError; end

end