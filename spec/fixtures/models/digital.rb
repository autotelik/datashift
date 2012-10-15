# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'paperclip'

class Digital < ActiveRecord::Base
  
  include Paperclip::Glue
  
  attr_accessible :attachment
  
  has_attached_file :attachment, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :path => ":rails_root/private/digitals/:id/:basename.:extension"
  
end