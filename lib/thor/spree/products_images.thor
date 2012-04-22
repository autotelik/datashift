# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     March 2012
# License::   MIT. Free, Open Source.
#
# Usage::
# bundle exec thor help datashift:spree
# bundle exec thor datashift:spree:products -i db/datashift/MegamanFozz20111115_load.xls -s 299S_
#
# bundle exec thor  datashift:spree:images -i db/datashift/imagebank -s -p 299S_
#

# Note, not DataShift, case sensitive, create namespace for command line : datashift
module Datashift
  
  puts "LOADED"
        
  class Spree < Thor     
  
    include DataShift::Logging
       
    desc "products", "Populate Spree Product/Variant data from .xls (Excel) or CSV file"
     
    method_option :input, :aliases => '-i', :required => true, :desc => "The import file (.xls or .csv)"
    method_option :sku_prefix, :aliases => '-s', :desc => "Prefix to add to each SKU in import file"
    method_option :verbose, :aliases => '-v', :type => :boolean, :desc => "Verbose logging"
    method_option :config, :aliases => '-c',  :type => :string, :desc => "Configuration file containg defaults or over rides in YAML"
    
    def products()

      # TODO - We're assuming run from a rails app/top level dir...
      # ...can we make this more robust ? e.g what about when using active record but not in Rails app, 
      require File.expand_path('config/environment.rb')
      
      input = options[:input]

      require 'product_loader'

      loader = DataShift::SpreeHelper::ProductLoader.new

      # YAML configuration file to drive defaults etc

      if(options[:config])
        raise "Bad Config - Cannot find specified file #{options[:config]}" unless File.exists?(options[:config])
        
        loader.configure_from( options[:config] )
      else
        loader.set_default_value('available_on', Time.now.to_s(:db) )
        loader.set_default_value('cost_price', 0.0 )
        loader.set_default_value('price', 0.0 )
      end
      
      loader.set_prefix('sku', options[:sku_prefix] ) if(options[:sku_prefix])
      
      puts "DataShift::Product starting upload from file: #{input}"

      loader.perform_load(input, :mandatory => ['sku', 'name', 'price'] )
    end
    
    
    #
    # => rake datashift:spree:images input=vendor/extensions/site/fixtures/images
    # => rake datashift:spree:images input=C:\images\photos large dummy=true
    #
    # => rake datashift:spree:images input=C:\images\taxon_icons skip_if_no_assoc=true klass=Taxon
    #
    desc "images", "Populate the DB with images.\nDefault location db/image_seeds, or specify :input=<path> or dir under db/image_seeds with :folder"
    
    # :dummy => dummy run without actual saving to DB
    method_option :input, :aliases => '-i', :required => true, :desc => "The import file (.xls or .csv)"
    
    method_option :process_when_no_assoc, :aliases => '-f', :type => :boolean, :desc => "Process image even if no Product found - force loading"
    

    method_option :sku, :aliases => '-s', :desc => "Lookup Product based on image name starting with sku"
    method_option :sku_prefix, :aliases => '-p', :desc => "Prefix to add to each SKU in import file"
    method_option :dummy, :aliases => '-d', :type => :boolean, :desc => "Dummy run, do not actually save Image or Product"
    method_option :verbose, :aliases => '-v', :type => :boolean, :desc => "Verbose logging"
    #method_option :config, :aliases => '-c',  :type => :string, :desc => "Configuration file containg defaults or over rides in YAML"
   
    def images()#, [:input, :folder, :dummy, :sku, :skip_if_no_assoc, :skip_if_loaded, :model] => :environment do |t, args|

      require File.expand_path('config/environment.rb')
      
      require 'image_loader'

      @image_cache = options[:input]
       
      puts "Using Product Name for lookup" unless(options[:sku])
      puts "Using SKU for lookup" if(options[:sku])
         
     
      attachment_klazz  = DataShift::SpreeHelper::get_spree_class('Product' )
      sku_klazz         = DataShift::SpreeHelper::get_spree_class('Variant' )

      # TODO generalise for any paperclip project, for now just Spree
      #begin
      #  attachment_klazz = Kernel.const_get(args[:model]) if(args[:model])
      # rescue NameError
      #  raise "Could not find contant for model #{args[:model]}"
      #end

      image_loader = DataShift::SpreeHelper::ImageLoader.new

      if(File.directory? @image_cache )
        logger.info "Loading Spree images from #{@image_cache}"

        missing_records = []
        Dir.glob("#{@image_cache}/**/*.{jpg,png,gif}") do |image_name|

          base_name = File.basename(image_name, '.*')
           
          logger.info "Processing #{base_name} : #{File.exists?(image_name)}"
           
          record = nil
          if(options[:sku])
            sku = base_name.slice!(/\w+/)
            sku.strip!
            base_name.strip!
            
            sku = "#{options[:sku_prefix]}#{sku}" if(options[:sku_prefix])

            record = sku_klazz.find_by_sku(sku)
            
            unless record   # try splitting up filename in various ways looking for the SKU
              sku.split( '_' ).each do |x| 
                x = "#{options[:sku_prefix]}#{x}" if(options[:sku_prefix])
                record = sku_klazz.find_by_sku(x)
                break if record
              end
            end
            
            record = record.product if(record)  # SKU stored on Variant but we want it's master Product
            
          else
            record = attachment_klazz.find_by_name(base_name)
          end
      
          if(record)
            logger.info "Found record for attachment : #{record.inspect}"
            exists = record.images.detect {|i| puts "COMPARE #{i.attachment_file_name} => #{image_name}"; i.attachment_file_name == image_name }
            
            if(options[:skip_if_loaded] && !exists.nil?)
              logger.info "Skipping - Image #{image_name} already loaded for #{attachment_klazz}"
              next
            end
          else
            missing_records << image_name
          end
          
          next if(options[:dummy]) # Don't actually create/upload to DB if we are doing dummy run

          # Check if Image must have an associated record
          if(record || (record.nil? && options[:process_when_no_assoc]))
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
            FileUtils.cp( i, 'MissingRecords')  unless(options[:dummy] == 'true')
          end
        end

      else
        puts "ERROR: Supplied Path #{@image_cache} not accesible"
        exit(-1)
      end
    end
  end

end