# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT.
#
require 'thor'

module DataShift

  class ThorExportBase < DataShift::DSThorBase

    class_option :associations, aliases: '-a',
                                type: :boolean,
                                desc: 'Include associations. Can be further refined by :with & :exclude'

    class_option :expand_associations, type: :boolean,
                 desc: 'Expand association data to multiple columns i.e 1 column per attribute'


    # See DataShift::Exporters::Configuration

    class_option :methods, type: :array,
                           desc: 'List of additional methods to call on model, useful for situations like delegated methods'

    class_option :with, type: :array,
                        desc: "Restrict association types. Choose from #{DataShift::ModelMethod.supported_types_enum.inspect}"

    class_option :exclude, type: :array,
                           desc: "Exclude association types. Choose from #{DataShift::ModelMethod.supported_types_enum.inspect}"

    class_option :remove,  type: :array,
                           desc: "Don't include this list of supplied fields"

    class_option :remove_rails, type: :boolean,
                                desc: "Remove standard Rails cols :  #{DataShift::Configuration.rails_columns.inspect}"

    class_option :json, type: :boolean,
                        desc: 'Export association data as json rather than hash'

  end

end
