=begin
t.string :name
t.decimal :budget
t.references :project
=end

class Owner < ActiveRecord::Base

  belongs_to :project, dependent: :destroy, optional: true

  has_many :digitals, dependent: :destroy

end
