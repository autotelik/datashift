

class Version < ActiveRecord::Base
  has_many :releases

  has_one :long_and_complex_table_linked_to_version
end
