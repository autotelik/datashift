# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     March 2012
# License::   MIT. Free, Open Source.
#
# Usage::
# bundle exec thor help datashift:reports:missing_images
# bundle exec thor datashift:spreeboot:cleanup
#
# Note, not DataShift, case sensitive, create namespace for command line : datashift

require 'excel_exporter'
  
module Datashift
        
    class Spreereports < Thor     
  
      include DataShift::Logging
       
      desc "no_image", "Spree Products without an image"
    
      def no_image(report = nil)

        require 'spree_helper'
        require 'csv_exporter'
        require 'image_loader'

        require File.expand_path('config/environment.rb')

        klass = DataShift::SpreeHelper::get_spree_class('Product')
      
        missing = klass.all.find_all {|p| p.images.size == 0 }
      
        puts "There are #{missing.size} Products (of #{klass.count}) without an associated Image"
      
        fname = report ? report : "missing_images"
      
        if(DataShift::Guards::jruby?)
          puts "Creating report #{fname}.xls"  
          DataShift::ExcelExporter.new( fname + '.xls' ).export( missing, :call => ['sku'] )
        else
          puts "Creating report #{fname}.csv"
          DataShift::CsvExporter.new( fname + '.csv' ).export( missing, :call => ['sku'] )
          puts missing.collect(&:name).join('\n')
        end   
      
# TODO - cross check file locations for possible candidates 
        #image_cache = DataShift::ImageLoading::get_files(@cross_check_location, options)
        
        # missing.each { 
      
        # puts images.inspect
      end
    end

end
