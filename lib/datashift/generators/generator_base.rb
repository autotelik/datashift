# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::  Base class for generators, which provide services to describe a Model in an external format
#
module DataShift

  class GeneratorBase

    include DataShift::Logging

    attr_accessor :config

    def initialize(config: nil)
      @config = config || DataShift::Configuration.call
    end

    # Prepare to generate with associations but then
    # calls a **derived generate** method i.e abstract to this base class
    #
    # file_name => Filename for generated template
    #
    def generate_with_associations(file_name, klass, options: {})
      generate(file_name, klass, associations: true, options: options)
    end

  end

end
