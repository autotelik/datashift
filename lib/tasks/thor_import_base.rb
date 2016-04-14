# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT.
#
require 'thor'

module DataShift

  class ThorImportBase < DataShift::DSThorBase

    class_option :model, aliases: '-m', required: true, desc: 'The related active record model'

    class_option :input, aliases: '-i', required: true, desc: 'The input file'

    class_option :loader, aliases: '-l', required: false, desc: 'Loader class to use'

    class_option :verbose, aliases: '-v', type: :boolean, desc: 'Verbose logging'

    class_option :config, aliases: '-c', desc: 'YAML config file with defaults, over-rides etc'

  end

end
