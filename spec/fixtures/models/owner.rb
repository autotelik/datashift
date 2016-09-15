=begin
t.string :name
t.decimal :budget
t.references :project
=end

class Owner < ActiveRecord::Base

  belongs_to :project, dependent: :destroy

  has_many :digitals, dependent: :destroy

end
