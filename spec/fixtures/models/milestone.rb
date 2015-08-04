

class Milestone < ActiveRecord::Base
  belongs_to :project
  # validate the name, cost

  delegate :title, :title=, to: :project

  attr_reader :x

  def milestone_setter=( x)
    @x = x
  end

end
