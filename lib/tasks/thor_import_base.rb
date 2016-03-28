# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT.
#
require 'thor'

module DataShift

  class ThorImportBase < DataShift::DSThorBase

    class_option :loader, aliases: '-l', required: false,
                 desc: 'Loader class to use'


    class_option :associations, aliases: '-a', type: :boolean,
                                desc: 'Include associations. Can be further refined by :with & :exclude'

    class_option :with, type: :array,
                        desc: "Restrict association types. Choose from #{DataShift::ModelMethod.supported_types_enum.inspect}"

    class_option :exclude, type: :array,
                           desc: "Exclude association types. Choose from #{DataShift::ModelMethod.supported_types_enum.inspect}"

    class_option :remove,  type: :array,
                           desc: "Don't include this list of supplied fields"

    class_option :verbose, :aliases => '-v', :type => :boolean, :desc => "Verbose logging"

    class_option :config, :aliases => '-c', :desc => "YAML config file with defaults, over-rides etc"

  end

end
