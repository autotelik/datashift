

class Milestone < ActiveRecord::Base
  belongs_to :project
  #validate the name, cost

  delegate :title, :title=, :to => :project
end
