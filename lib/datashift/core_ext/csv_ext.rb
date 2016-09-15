# Copyright:: Autotelik Media Ltd
# Author ::   Tom Statter
#
require 'csv'
require 'datashift/column_packer'
require 'datashift/model_methods/model_method'

class CSV

  include DataShift::ColumnPacker

  # Convert an AR instance to a set of CSV columns
  # Additional non instance data can be included by supplying list of methods to call
  # on the record
  #
  # Returns the data added
  #
  def ar_to_csv(record, remove_list = [], method_list = [])

    serializable_hash = record.serializable_hash(except: remove_list)

    csv_data = serializable_hash.values.collect { |c| escape_for_csv(c) }

    [*method_list].each do |x|
      csv_data << escape_for_csv(record.send(x)) if record.respond_to?(x)
    end

    csv_data
  end

  def ar_to_row(record, remove_list = [], method_list = [])
    add_row( ar_to_csv(record, remove_list, method_list) )
  end

  def ar_association_to_csv(record, model_method, _options = {})
    # pack association instances into single column
    csv_data = if DataShift::ModelMethod.association_type?(model_method.operator_type)
                 record_to_column( record.send(model_method.operator) )
               else
                 escape_for_csv( record.send(model_method.operator) )
               end

    csv_data
  end

end
