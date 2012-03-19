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
    
    def cleanup()  #, [:input, :verbose, :sku_prefix] => :environment do |t, args|

     require 'spree_helper'

      require File.expand_path('config/environment.rb')
    
      %w{Image OptionType OptionValue Product Property ProductGroup ProductProperty ProductOptionType Variant Taxonomy Taxon Zone}.each do |k|
        instance_variable_set("@#{k}_klass", DataShift::SpreeHelper::get_spree_class(k)) 
        puts "Clearing model #{DataShift::SpreeHelper::get_spree_class(k)}"
        instance_variable_get("@#{k}_klass").delete_all
      end
    end
  
  end

end