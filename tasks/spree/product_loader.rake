# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Feb 2011
# License::   MIT. Free, Open Source.
#
# REQUIRES:   JRuby access to Java
#
# Usage::
#
# e.g.  => jruby -S rake datashift:spree:products input=vendor/extensions/autotelik/fixtures/SiteSpreadsheetInfo.xls
#       => jruby -S rake datashift:spree:products input=C:\MyProducts.xls verbose=true
#
require 'datashift'

namespace :datashift do

  namespace :spree do

    desc "Populate Spree Product/Variant data from .xls (Excel) or CSV file"
    task :products, [:input, :verbose, :sku_prefix] => :environment do |t, args|

      input = ENV['input']

      raise "USAGE: jruby -S rake  datashift:spree:products input=excel_file.xls" unless input
      raise "ERROR: Could not find file #{args[:input]}" unless File.exists?(input)

      require 'product_loader'

      # COLUMNS WITH DEFAULTS - TODO create YAML configuration file to drive defaults etc

      loader = DataShift::ProductLoader.new

      loader.set_default_value('available_on', Time.now.to_s(:db) )
      loader.set_default_value('cost_price', 0.0 )

      loader.set_prefix('sku', args[:sku_prefix] ) if(args[:sku_prefix])
      
      puts "Loading from file: #{input}"

      loader.perform_load(input, :mandatory => ['sku', 'name', 'price'] )
    end
  end 

end