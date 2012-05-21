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
module Datashift
        
  class Spreeboot < Thor     
  
    include DataShift::Logging
       
    desc "cleanup", "Remove Spree Product/Variant data from DB"
    
    def cleanup()

      require 'spree_helper'

      require File.expand_path('config/environment.rb')

      cleanup =  %w{ Image OptionType OptionValue 
                    Product Property ProductGroup ProductProperty ProductOptionType 
                    Variant Taxonomy Taxon Zone
      }

      cleanup.each do |k|
        klass = DataShift::SpreeHelper::get_spree_class(k)
      if(klass)
        puts "Clearing model #{klass}"
        klass.delete_all
      else
        puts "WARNING - Coulod not find AR model for class name #{k}"
      end
        
    end
      
    if(File.exists?('public/spree/products') )
      puts "Removing old Product assets from 'public/spree/products'"
      FileUtils::rm_rf('public/public/spree/products') 
    end
      
    FileUtils::rm_rf('MissingRecords') if(File.exists?('MissingRecords') )
      
  end
  
end

end