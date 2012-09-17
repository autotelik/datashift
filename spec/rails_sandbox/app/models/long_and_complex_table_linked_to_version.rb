
# Join Table with additional columns
class LongAndComplexTableLinkedToVersion < ActiveRecord::Base

  belongs_to :version
end
