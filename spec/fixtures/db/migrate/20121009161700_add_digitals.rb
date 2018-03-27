# Author ::   Tom Statter
# Date ::     Oct 2012
# License::   MIT
#
# Details::   Migration for paperclip specs


# TODO - can we get the version dynamically ? cos when we bump the version of Rails this needs to match
class AddDigitals < ActiveRecord::Migration[4.2]

  def self.up

    create_table :digitals do |t|
      t.integer :owner_id
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.timestamps null: false
    end

  end

  def self.down
    drop_table :digitals
  end
end
