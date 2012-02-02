# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Jan 2011
# License::   MIT. Free, Open Source.
#
require 'loader_base'

module DataShift

  class ImageLoader < LoaderBase

    def initialize(image = nil)
      super( Image, image )
      raise "Failed to create Image for loading" unless @load_object
    end

    # Note the Spree Image model sets default storage path to
    # => :path => ":rails_root/public/assets/products/:id/:style/:basename.:extension"

    def process( image_path, record = nil)

      unless File.exists?(image_path)
        puts "ERROR : Invalid Path"
        return
      end

      alt = (record and record.respond_to? :name) ? record.name : ""

      @load_object.alt = alt

      begin
        @load_object.attachment = File.new(image_path, "r")
      rescue => e
        puts e.inspect
        puts "ERROR : Failed to read image #{image_path}"
        return
      end

      @load_object.attachment.reprocess!
      @load_object.viewable = record if record

      puts @load_object.save ? "Success: Uploaded Image: #{@load_object.inspect}" : "ERROR : Problem saving to DB Image: #{@load_object}"
    end
  end

end