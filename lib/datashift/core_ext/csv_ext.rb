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
    add_row( to_headers(klass, options) )
  end

  # Convert an AR instance to a set of CSV columns
  # Additional non instance data can be included by supplying list of methods to call
  # on the record
  def ar_to_csv(record, options = {})
    csv_data = record.serializable_hash.values.collect { |c| escape_for_csv(c) }

    [*options[:methods]].each { |x| csv_data << escape_for_csv(record.send(x)) if(record.respond_to?(x)) } if(options[:methods])

    add_row(csv_data)
  end

end
