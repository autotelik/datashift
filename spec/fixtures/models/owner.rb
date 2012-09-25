

class Owner < ActiveRecord::Base
  belongs_to :project
  
  attr_accessible :avatar
  has_attached_file :avatar, :styles => { :medium => "300x300>", :thumb => "100x100>" }

end
