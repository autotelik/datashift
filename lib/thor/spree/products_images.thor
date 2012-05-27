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
  

    desc "attach_images", "Populate Products with images from Excel/CSV\nProvide column SKU or Name\nProvide column 'attachment' containing full path to image"
    # :dummy => dummy run without actual saving to DB
    method_option :input, :aliases => '-i', :required => true, :desc => "The 2 column import file (.xls or .csv)"
    
    def attach_images()

      require File.expand_path('config/environment.rb')
      
      require 'image_loader'
      
      image_klazz = DataShift::SpreeHelper::get_spree_class('Image' )
      
      # force inclusion means add to operator list even if not present
      options = { :force_inclusion => ['sku', 'attachment'] } if(SpreeHelper::version.to_f > 1 )
    
      loader = DataShift::SpreeHelper::ImageLoader.new(nil, options)
    
      loader.perform_load( options[:input], options )
    end
  
    
    #
    # => rake datashift:spree:images input=vendor/extensions/site/fixtures/images
    # => rake datashift:spree:images input=C:\images\photos large dummy=true
    #
    # => rake datashift:spree:images input=C:\images\taxon_icons skip_if_no_assoc=true klass=Taxon
    #
    desc "images", "Populate the DB with images from a directory where image names map to Product Sku/Name"
    
    # :dummy => dummy run without actual saving to DB
    method_option :input, :aliases => '-i', :required => true, :desc => "The import file (.xls or .csv)"
    
    method_option :process_when_no_assoc, :aliases => '-f', :type => :boolean, :desc => "Process image even if no Product found - force loading"
    
    method_option :sku, :aliases => '-s', :desc => "Lookup Product based on image name starting with sku"
    method_option :sku_prefix, :aliases => '-p', :desc => "Prefix to add to each SKU in import file"
    method_option :dummy, :aliases => '-d', :type => :boolean, :desc => "Dummy run, do not actually save Image or Product"
    method_option :verbose, :aliases => '-v', :type => :boolean, :desc => "Verbose logging"
    method_option :config, :aliases => '-c',  :type => :string, :desc => "Configuration file for Image Loader in YAML"
    method_option :split_file_name_on,  :type => :string, :desc => "delimiter to progressivley split filename for Prod lookup", :default => '_'
    method_option :case_sensitive, :type => :boolean, :desc => "Use case sensitive where clause to find Product"
    method_option :use_like, :type => :boolean, :desc => "Use LIKE 'string%' instead of = 'string' in where clauses"
  
    def images()

      require File.expand_path('config/environment.rb')
      
      require 'image_loader'
            
      @verbose = options[:verbose]
       
      puts "Using Product Name for lookup" unless(options[:sku])
      puts "Using SKU for lookup" if(options[:sku])
       
      image_klazz = DataShift::SpreeHelper::get_spree_class('Image' )
       
      attachment_klazz  = DataShift::SpreeHelper::get_spree_class('Product' )
      attachment_field  = 'name'

      if(options[:sku])
        attachment_klazz =  DataShift::SpreeHelper::get_spree_class('Variant' ) 
        attachment_field = 'sku'
      end
      
      # TODO generalise for any paperclip project, for now just Spree
      #begin
      #  attachment_klazz = Kernel.const_get(args[:model]) if(args[:model])
      # rescue NameError
      #  raise "Could not find contant for model #{args[:model]}"
      #end

      image_loader = DataShift::SpreeHelper::ImageLoader.new(nil, options.dup)

      @loader_config = {}
      
      if(options[:config])
        raise "Bad Config - Cannot find specified file #{options[:config]}" unless File.exists?(options[:config])
        
        image_loader.configure_from( options[:config] )
        
        @loader_config = YAML::load( File.open(options[:config]) )
        
        @loader_config = @loader_config['ImageLoader']
      end
      
      puts "CONFIG: #{@loader_config.inspect}"
      
      @image_cache = options[:input]
      
      unless(File.directory? @image_cache )
        puts "ERROR: Supplied Path #{@image_cache} not accesible"
        exit(-1)
      end
      
      logger.info "Loading Spree images from #{@image_cache}"

      missing_records = []
         
      # unless record   # try splitting up filename in various ways looking for the SKU
      split_on = @loader_config[:split_file_name_on] || options[:split_file_name_on]
        
      Dir.glob("#{@image_cache}/**/*.{jpg,png,gif}") do |image_name|

        base_name = File.basename(image_name, '.*')
        base_name.strip!
                       
        logger.info "Processing image file #{base_name} : #{File.exists?(image_name)}"
           
        record = nil
           
        puts "Search for product for image file [#{base_name}]" if(@verbose)
            
        record = image_loader.get_record_by(attachment_klazz, attachment_field, base_name)
          
        # try seperate portions of the filename, front -> back
        base_name.split(split_on).each do |x| 
          record = image_loader.get_record_by(attachment_klazz, attachment_field, x)
          break if record
        end unless(record)
            
        # this time try sequentially scanning
        base_name.split(split_on).inject("") do |str, x| 
          record = image_loader.get_record_by(attachment_klazz, attachment_field, "#{str}#{x}")
          break if record
          x
        end unless(record)
          
        record = record.product if(record && record.respond_to?(:product))  # SKU stored on Variant but we want it's master Product
      
        if(record)
          logger.info "Found record for attachment : #{record.inspect}"
    
          if(options[:skip_if_loaded])
            exists = record.images.detect {|i| i.attachment_file_name == image_name }
            
            logger.info "Skipping - Image #{image_name} already loaded for #{attachment_klazz}"
            next if(exists)
          end
        else
          missing_records << image_name
        end
          
        next if(options[:dummy]) # Don't actually create/upload to DB if we are doing dummy run

        # Check if Image must have an associated record
        if(record || (record.nil? && options[:process_when_no_assoc]))
          image_loader.reset()
          puts "Adding Image #{image_name} to Product #{record.name}" if(@verbose)
          logger.info("Adding Image #{image_name} to Product #{record.name}")
          image_loader.create_image(image_klazz, image_name, record)
        end

      end

      unless missing_records.empty?
        FileUtils.mkdir_p('MissingRecords') unless File.directory?('MissingRecords')
        
        puts 'MISSING Records Report>>'
        missing_records.each do |i|
          puts "Copy #{i} to MissingRecords folder"
          FileUtils.cp( i, 'MissingRecords')  unless(options[:dummy] == 'true')
        end
      end

      puts "Dummy Run Complete- if happy run without -d" if(options[:dummy])
   
    end
   
  end

end