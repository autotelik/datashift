# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'paperclip'

class Digital < ActiveRecord::Base

  include Paperclip::Glue

  # Rails 4 move to Controller
  # attr_accessible :attachment

  has_attached_file :attachment,
                    styles: { medium: '300x300>', thumb: '100x100>' },
                    path: ':rails_root/private/digitals/:id/:basename.:extension'

  # Paperclip version 4.0 : all attachments are required to include a content_type validation,
  # a file_name validation, or to explicitly state that they're not going to have either.
  # Paperclip raises MissingRequiredValidatorError error if you do not do this.
  validates_attachment_content_type :attachment,
                                    content_type: ['image/jpg', 'image/jpeg', 'image/png', 'image/gif']
end
