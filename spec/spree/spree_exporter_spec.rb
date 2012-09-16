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
require 'excel_exporter'

describe 'SpreeExporter' do

  include SpecHelper
  extend SpecHelper
    
  before(:all) do
    before_all_spree
    results_clear()
  end

  before do
    
    before_each_spree   # inits tests, cleans DB setups model types
    
    
    # Create some test data
    root = @Taxonomy_klass.create( :name => 'Paintings' )
    
    @Taxon_klass.create( :name => 'Landscape', :description => "Nice paintings", :taxonomy_id => root.id )
    @Taxon_klass.create( :name => 'Sea', :description => "Waves and sand", :taxonomy_id => root.id )
      
  end

  it "should export any Spree model to .xls spreedsheet" do

    expect = result_file('taxon_export_spec.xls')

    exporter = ExcelExporter.new(expect)

    items = @Taxon_klass.all

    exporter.export(items)

    File.exists?(expect).should be_true
  end

  it "should export a Spree model and associations to .xls spreedsheet" do

    expect = result_file('taxon_and_assoc_export_spec.xls')

    exporter = ExcelExporter.new(expect)

    items = @Taxon_klass.all
      
    exporter.export_with_associations(@Taxon_klass, items)

    File.exists?(expect).should be_true

  end
    
end