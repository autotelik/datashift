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
    method_option :config, :aliases => '-c',  :type => :string, :desc => "Configuration file for Image Loader in YAML"
    
   
    def images()

      require File.expand_path('config/environment.rb')
      
      require 'image_loader'
       
      puts "Using Product Name for lookup" unless(options[:sku])
      puts "Using SKU for lookup" if(options[:sku])
           
      attachment_klazz  = DataShift::SpreeHelper::get_spree_class('Product' )
      attachment_field  = 'name'
      image_klazz       = DataShift::SpreeHelper::get_spree_class('Image' )

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

      image_loader = DataShift::SpreeHelper::ImageLoader.new

      @loader_config = {}
      
      if(options[:config])
        raise "Bad Config - Cannot find specified file #{options[:config]}" unless File.exists?(options[:config])
        
        image_loader.configure_from( options[:config] )
        
        @loader_config = YAML::load( File.open(options[:config]) )
        
        @loader_config = @loader_config['ImageLoader']
      end
      
      puts "CONFIG: #{@loader_config.inspect}"
      
      @image_cache = options[:input]
      
      if(File.directory? @image_cache )
        logger.info "Loading Spree images from #{@image_cache}"

        missing_records = []
        Dir.glob("#{@image_cache}/**/*.{jpg,png,gif}") do |image_name|

          base_name = File.basename(image_name, '.*')
          base_name.strip!
                       
          logger.info "Processing image #{base_name} : #{File.exists?(image_name)}"
           
          record = nil
           
          put "Processing image [#{base_name}]"
           
          # unless record   # try splitting up filename in various ways looking for the SKU
          split_on = @loader_config[:split_file_name_on] || '_'
              
          base_name.split(split_on).each do |x| 
            record = get_record_by(attachment_klazz, attachment_field, x)
            break if record
          end
            
          record = record.product if(record)  # SKU stored on Variant but we want it's master Product
      
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
            puts "Processing Image #{image_name}"
            image_loader.create_image(image_klazz, image_name, record)
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

        puts "Dummy Run - if happy run without -d" if(options[:dummy])
      else
        puts "ERROR: Supplied Path #{@image_cache} not accesible"
        exit(-1)
      end
    end
   
    private
    
    def get_record_by(klazz, field, value)
      x =  (options[:sku_prefix]) ? "#{options[:sku_prefix]}#{value}" : value

      if(@loader_config['case_sensitive'])
        puts "Search case sensitive for [#{x}] on #{field}"
         return klazz.find(:first, :conditions => [ "? = ?", field, x ])
      else
        puts "Search for [#{x}] on #{field}"
        return klazz.find(:first, :conditions => [ "lower(?) = ?", field, x.downcase ])
      end
    end
  end

end