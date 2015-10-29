

# had_and_belongs to join table
class Category < ActiveRecord::Base
  has_and_belongs_to_many :projects
end
