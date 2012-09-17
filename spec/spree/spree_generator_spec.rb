# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Summer 2011
#
# License::   MIT - Free, OpenSource
#
# Details::   Specification for Spree generator aspect of datashift gem.
#
#             Provides Loaders and rake tasks specifically tailored for uploading or exporting
#             Spree Products, associations and Images
#
require File.join(File.expand_path(File.dirname(__FILE__)  + '/..'), "spec_helper")

require 'spree_helper'
require 'excel_generator'

include DataShift
  
describe 'SpreeGenerator' do

  include SpecHelper
  extend SpecHelper
    
  before(:all) do
    before_all_spree
  end

  before do
       
    before_each_spree   # inits tests, cleans DB setups model types
    
    # Create some test data
    root = @Taxonomy_klass.create( :name => 'Paintings' )
    
    if(SpreeHelper::version.to_f > 1 )
      root.taxons.create( :name => 'Landscape' )
      root.taxons.create( :name => 'Sea' )
    else
      @Taxon_klass.create( :name => 'Landscape', :taxonomy => root )
      @Taxon_klass.create( :name => 'Sea', :taxonomy => root )
    end
  end

  it "should export any Spree model to .xls spreedsheet" do

    expect = result_file('taxonomy_export_spec.xls')

    excel = ExcelGenerator.new(expect)

    excel.generate(@Taxonomy_klass)

    File.exists?(expect).should be_true
    
    puts "You can check results manually in file #{expect}"
    
    expect = result_file('taxon_export_spec.xls')

    excel.filename = expect

    excel.generate(@Taxon_klass)

    File.exists?(expect).should be_true
    
    puts "You can check results manually in file #{expect}"
    
  end

  it "should export Spree Product and all associations to .xls spreedsheet" do

    expect = result_file('product_and_assoc_export_spec.xls')

    excel = ExcelGenerator.new(expect)
      
    excel.generate_with_associations(@Product_klass)

    File.exists?(expect).should be_true

    puts "You can check results manually in file #{expect}"
    
  end
    
  it "should be able to exclude single associations from template" do

    expect = result_file('product_and_assoc_export_spec.xls')

    excel = ExcelGenerator.new(expect)
      
    excel.generate_with_associations(@Product_klass, :exclude => :has_many)

    File.exists?(expect).should be_true

    puts "You can check results manually in file #{expect}"
    
  end
  
end