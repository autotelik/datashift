

# Join Table with additional columns
class LoaderRelease < ActiveRecord::Base

  belongs_to :project, optional: true
  belongs_to :version, optional: true

  # validate the name
end
