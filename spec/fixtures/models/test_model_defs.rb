# A set of models and associations we can use in our specs to test
# basic database columns and also relationships

# See Companion migration spec/db/migrate

class Project < ActiveRecord::Base

  has_one  :owner

  has_many :milestones

  has_many :loader_releases
  has_many :versions, :through => :loader_releases


  #has_many :release_versions, :through => :loader_releases, :source => :versions

  has_and_belongs_to_many :categories

  attr_accessible  :value_as_string, :value_as_boolean, :value_as_double
  
  def multiply
    10 * value_as_double
  end
  
end

class Owner < ActiveRecord::Base
  belongs_to :project
end

class Milestone < ActiveRecord::Base
  belongs_to :project
  #validate the name, cost

  delegate :title, :title=, :to => :project
end

# had_and_belongs to join table
class Category < ActiveRecord::Base
  has_and_belongs_to_many :projects
end


class Version < ActiveRecord::Base
  has_many :releases

  has_one :long_and_complex_table_linked_to_version
end

# Join Table with additional columns
class LoaderRelease < ActiveRecord::Base
  
  belongs_to :project
  belongs_to :version

  #validate the name
end

class Empty < ActiveRecord::Base
end

# Join Table with additional columns
class LongAndComplexTableLinkedToVersion < ActiveRecord::Base

  belongs_to :version
end
