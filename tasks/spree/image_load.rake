# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Feb 2011
# License::   MIT
#
# Usage::
#
# => rake datashift:spree:images input=vendor/extensions/site/fixtures/images
# => rake datashift:spree:images input=C:\images\photos large dummy=true
#
# => rake datashift:spree:images input=C:\images\taxon_icons skip_if_no_assoc=true klass=Taxon
#
namespace :datashift do

  namespace :spree do

    desc "Populate the DB with images.\nDefault location db/image_seeds, or specify :input=<path> or dir under db/image_seeds with :folder"
    # :dummy => dummy run without actual saving to DB
    task :images, :input, :folder, :dummy, :sku, :skip_if_no_assoc, :skip_if_loaded, :model, :needs => :environment do |t, args|

      require 'image_loader'

      raise "USAGE: Please specify one of :input or :folder" if(args[:input] && args[:folder])
      puts  "SKU not specified " if(args[:input] && args[:folder])

      if args[:input]
        @image_cache = args[:input]
      else
        @image_cache =  File.join(Rails.root, "db", "image_seeds")
        @image_cache =  File.join(@image_cache, args[:folder]) if(args[:folder])
      end

      attachment_klazz = Product

      begin
        attachment_klazz = Kernel.const_get(args[:model]) if(args[:model])
      rescue NameError
        attachment_klazz = Product
      end

      image_loader = ImageLoader.new

      if(File.exists? @image_cache )
        puts "Loading images from #{@image_cache}"

        missing_records = []
        Dir.glob("#{@image_cache}/*.{jpg,png,gif}") do |image_name|

          puts "Processing #{image_name} : #{File.exists?(image_name)}"
          base_name = File.basename(image_name, '.*')

          record = nil
          if(attachment_klazz == Product && args[:sku])
            sku = base_name.slice!(/\w+/)
            sku.strip!
            base_name.strip!

            puts "Looking fo SKU #{sku}"
            record = Variant.find_by_sku(sku)
            if record
              record = record.product   # SKU stored on Variant but we want it's master Product
            else
              puts "Looking for NAME [#{base_name}]"
              record = attachment_klazz.find_by_name(base_name)
            end
          else
            puts "Looking for #{attachment_klazz.name} with NAME [#{base_name}]"
            record = attachment_klazz.find_by_name(base_name)
          end
      
          if(record)
            puts "Found record for attachment : #{record.inspect}"
            exists = record.images.detect {|i| puts "COMPARE #{i.attachment_file_name} => #{image_name}"; i.attachment_file_name == image_name }
            puts "Found existing attachments [#{exists}]" unless(exists.nil?)
            if(args[:skip_if_loaded] && !exists.nil?)
              puts "Skipping - Image #{image_name} already loaded for #{attachment_klazz}"
              next
            end
          else
            missing_records << image_name
          end

          # Now do actual upload to DB unless we are doing a dummy run,
          # or the Image must have an associated record
          unless(args[:dummy] == 'true' || (args[:skip_if_no_assoc] && record.nil?))
            image_loader.reset()
            puts "Process Image"
            image_loader.process( image_name, record )
          end

        end

        unless missing_records.empty?
          FileUtils.mkdir_p('MissingRecords') unless File.directory?('MissingRecords')
        
          puts '\nMISSING Records Report>>'
          missing_records.each do |i|
            puts "Copy #{i} to MissingRecords folder"
            FileUtils.cp( i, 'MissingRecords')  unless(args[:dummy] == 'true')
          end
        end

      else
        puts "ERROR: Supplied Path #{@image_cache} not accesible"
        exit(-1)
      end
    end
  end
end