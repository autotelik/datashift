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
require File.dirname(__FILE__) + '/spec_helper'

require 'spree_helper'
require 'excel_generator'

include DataShift
  
describe 'SpreeLoader' do

  before(:all) do
    SpecHelper::before_all_spree
  end

  before do
    
    include SpecHelper
    extend SpecHelper
      
    before_each_spree   # inits tests, cleans DB setups model types
    
    # Create some test data
    root = @Taxonomy_klass.create( :name => 'Paintings' )
    
    @Taxon_klass.create( :name => 'Landscape', :taxonomy => root )
    @Taxon_klass.create( :name => 'Sea', :taxonomy => root )
      
  end

  it "should export any Spree model to .xls spreedsheet" do

    expect = result_file('taxonomy_export_spec.xls')

    gen = ExcelGenerator.new(expect)

    items = @Taxonomy_klass.all

    gen.export(items)

    File.exists?(expect).should be_true
  end

  it "should export a Spree model and associations to .xls spreedsheet" do

    expect = result_file('taxonomy_and_assoc_export_spec.xls')

    gen = ExcelGenerator.new(expect)

    items = @Taxonomy_klass.all
      
    gen.generate_with_associations(@Taxonomy_klass, items)

    File.exists?(expect).should be_true

  end
    
end