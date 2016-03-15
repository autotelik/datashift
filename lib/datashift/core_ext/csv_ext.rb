# Copyright:: Autotelik Media Ltd
# Author ::   Tom Statter
#
require 'csv'

class CSV

  # TOFIX .. now we use CSV class this probably not needed
  include DataShift::ColumnPacker

  # Helpers for dealing with Active Record models and collections
  #
  # options[:with] => [SYMBOLS]
  #     Specify array of operators/associations to include - possible values :
  #         [:assignment, :belongs_to, :has_one, :has_many]
  #
  # options[:remove] - List of headers to remove from generated template
  #
  # options[:remove_rails] - Remove standard Rails cols like id, created_at etc
  #
  def ar_to_headers(klass, options = {})
    add_row( klass_to_headers(klass, options) )
  end

  # Convert an AR instance to a set of CSV columns
  # Additional non instance data can be included by supplying list of methods to call
  # on the record
  #
  # Returns the data added
  #
  def ar_to_csv(record, remove_list = [], options = {})

    serializable_hash = record.serializable_hash(except: remove_list)

    csv_data = serializable_hash.values.collect { |c| escape_for_csv(c) }

    [*options[:methods]].each do |x|
      csv_data << escape_for_csv(record.send(x)) if record.respond_to?(x)
    end

    csv_data
  end

  def ar_to_row(record, remove_list = [], options = {})
    add_row( ar_to_csv(record, remove_list, options) )
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
