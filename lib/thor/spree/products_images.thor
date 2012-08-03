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
    method_option :sku_prefix, :aliases => '-s', :desc => "Prefix to add to each SKU before saving Product"
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

      options = {:mandatory => ['sku', 'name', 'price']}
    
      # In >= 1.1.0 Image moved to master Variant from Product
      options[:force_inclusion] = ['images'] if(DataShift::SpreeHelper::version.to_f > 1 )
      
      loader.perform_load(input, options)
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
    # => thor datashift:spree:images input=vendor/extensions/site/fixtures/images
    # => rake datashift:spree:images input=C:\images\photos large dummy=true
    #
    # => rake datashift:spree:images input=C:\images\taxon_icons skip_if_no_assoc=true klass=Taxon
    #
    desc "images", "Populate the DB with images from a directory\nwhere image names contain somewhere the Product Sku/Name"
    
    # :dummy => dummy run without actual saving to DB
    method_option :input, :aliases => '-i', :required => true, :desc => "The input path containing images (.jpg, .jpeg .gif, .png)"
    
    method_option :recursive, :aliases => '-r', :type => :boolean, :desc => "Scan sub directories of input for images"
     
    method_option :sku, :aliases => '-s', :desc => "Lookup Product based on image name starting with sku"
    method_option :sku_prefix, :aliases => '-p', :desc => "Prefix to add to each SKU in import file before attempting lookup"
    method_option :dummy, :aliases => '-d', :type => :boolean, :desc => "Dummy run, do not actually save Image or Product"
    
    method_option :process_when_no_assoc, :aliases => '-f', :type => :boolean, :desc => "Process image even if no Product found - force loading"
    method_option :skip_when_assoc, :aliases => '-x', :type => :boolean, :desc => "DO not process image if Product already has image"
    
    method_option :verbose, :aliases => '-v', :type => :boolean, :desc => "Verbose logging"
    method_option :config, :aliases => '-c',  :type => :string, :desc => "Configuration file for Image Loader in YAML"
    method_option :split_file_name_on,  :type => :string, :desc => "delimiter to progressivley split filename for Prod lookup", :default => '_'
    method_option :case_sensitive, :type => :boolean, :desc => "Use case sensitive where clause to find Product"
    method_option :use_like, :type => :boolean, :desc => "Use sku/name LIKE 'string%' instead of sku/name = 'string' in where clauses to find Product"
  
    def images()

      require File.expand_path('config/environment.rb')
      
      require 'spree/image_loader'
            
      @verbose = options[:verbose]
       
      puts "Using Product Name for lookup" unless(options[:sku])
      puts "Using SKU for lookup" if(options[:sku])
       
      image_klazz = DataShift::SpreeHelper::get_spree_class('Image' )
       
      attachment_klazz  = DataShift::SpreeHelper::get_spree_class('Product' )
      attachment_field  = 'name'

      if(options[:sku] || SpreeHelper::version.to_f > 1)
        attachment_klazz =  DataShift::SpreeHelper::get_spree_class('Variant' ) 
        attachment_field = 'sku'
      end

      image_loader = DataShift::SpreeHelper::ImageLoader.new(nil, options)
 
      if(options[:config])
        raise "Bad Config - Cannot find specified file #{options[:config]}" unless File.exists?(options[:config])
        
        image_loader.configure_from( options[:config] )
      end

      loader_config = image_loader.options
 
      puts "CONFIG: #{loader_config.inspect}"
      puts "OPTIONS #{options.inspect}"
      
      @image_path = options[:input]
      
      unless(File.exists?(@image_path))
        puts "ERROR: Supplied Path [#{@image_path}] not accesible"
        exit(-1)
      end
      
      logger.info "Loading Spree images from #{@image_path}"

      missing_records = []
         
      # try splitting up filename in various ways looking for the SKU
      split_on = loader_config['split_file_name_on'] || options[:split_file_name_on]
       
      puts "Will scan image names splitting on delimiter : #{split_on}"
      
      image_cache = DataShift::ImageLoading::get_files(@image_path, options)
      
      image_cache.each do |image_name|

        image_base_name = File.basename(image_name)
        
        base_name = File.basename(image_name, '.*')
        base_name.strip!
                       
        logger.info "Processing image file #{base_name} : #{File.exists?(image_name)}"
           
        record = nil
                   
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
    
          if(options[:skip_when_assoc])
            
            paper_clip_name = image_base_name.gsub(Paperclip::Attachment::default_options[:restricted_characters], '_')
            
            exists = record.images.detect {|i| puts "Check #{paper_clip_name} matches #{i.attachment_file_name}"; i.attachment_file_name == paper_clip_name }
            if(exists)
              rid = record.respond_to?(:name) ? record.name : record.id
              puts "Skipping Image #{image_name} already loaded for #{rid}"
              logger.info "Skipping - Image #{image_name} already loaded for #{attachment_klazz}"
              next 
            end
          end
        else
          missing_records << image_name
        end
          
        next if(options[:dummy]) # Don't actually create/upload to DB if we are doing dummy run

        # Check if Image must have an associated record
        if(record || (record.nil? && options[:process_when_no_assoc]))
          image_loader.reset()
          
          logger.info("Adding Image #{image_name} to Product #{record.name}")
          image_loader.create_image(image_klazz, image_name, record)
          puts "Added Image #{File.basename(image_name)} to Product #{record.sku} : #{record.name}" if(@verbose)
        end

      end

      unless missing_records.empty?
        FileUtils.mkdir_p('MissingRecords') unless File.directory?('MissingRecords')
        
        puts "WARNING : #{missing_records.size} of #{image_cache.size} images could not be attached to a Product"
        puts 'Copying all images with MISSING Records to ./MissingRecords >>'
        missing_records.each do |i|
          puts "Copy #{i} to MissingRecords folder"
          FileUtils.cp( i, 'MissingRecords')  unless(options[:dummy] == 'true')
        end
      else
        puts "All images (#{image_cache.size}) were succesfully attached to a Product"
      end

      puts "Dummy Run Complete- if happy run without -d" if(options[:dummy])
   
    end
   
  end

end