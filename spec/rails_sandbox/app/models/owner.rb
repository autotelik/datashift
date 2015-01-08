class Owner < ActiveRecord::Base
    
  belongs_to :project, :dependent => :destroy
  
  has_many :digitals, :dependent => :destroy
  
end
