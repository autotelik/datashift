# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     March 2012
# License::   MIT. Free, Open Source.
#
# Usage::
# bundle exec thor help datashift:spreeboot
# bundle exec thor datashift:spreeboot:cleanup
#
# Note, not DataShift, case sensitive, create namespace for command line : datashift

require 'excel_exporter'
  
module Datashift
        
  class Reports < Thor     
  
    include DataShift::Logging
       
    desc "missing_images", "Spree Products without an image"
    
    def missing_images(report = nil)

      require 'spree_helper'
      require 'image_loader'

      require File.expand_path('config/environment.rb')

      klass = DataShift::SpreeHelper::get_spree_class('Product')
      
      missing = klass.all.find_all {|p| p.images.size == 0 }
      
      puts "There are #{missing.size} Products without an associated Image"
      
      if(DataShift::Guards::jruby?)
        fname = report ? report : "missing_images.xls"
        DataShift::ExcelExporter.new( fname ).export( missing )
      else
        puts missing.collect(&:name).inspect
      end   
      
      @drop_box = "/home/stattert/Dropbox/DaveWebsiteInfo/"

      @image_list  = %w{
    010InafixTheArmourGodAllFolders 
    01Figuresurbanlandscapepaintings 
    01FinishedArtPrints    
    02Seascapespainting  
    03Landscapes 
    04Spain 
    07_Mar 
    09Powerpointsermonaids
      }
  
      options = { :recursive => true }
    
      images = @image_list.collect do |p| 
        DataShift::ImageLoading::get_files(File.join(@drop_box,p), options)
      end
      
      puts images.inspect
    end
  end
end