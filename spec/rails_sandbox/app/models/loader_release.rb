

# Join Table with additional columns
class LoaderRelease < ActiveRecord::Base
  
  belongs_to :project
  belongs_to :version

  #validate the name
end
