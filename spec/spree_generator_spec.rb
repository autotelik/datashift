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

    # we are not a Spree project, nor is it practical to externally generate
    # a complete Spree application for testing so we implement a mini migrate/boot of our own
    Spree.load()            # require Spree gems

    # key to YAML db e.g  test_memory, test_mysql
    db_connect( 'test_spree_standalone' )    

    Spree.boot            # create a sort-of Spree app
    
    Spree.migrate_up      # create an sqlite Spree database on the fly
  end

  before do
  end

  it "should export any Spree model to .xls spreedsheet" do

      expect = result_file('optionstypes_export_spec.xls')

      gen = ExcelGenerator.new(expect)

      items = OptionType.all

      gen.export(items)

      File.exists?(expect).should be_true
    end

    it "should export a Spree model and associations to .xls spreedsheet" do

      expect = result_file('shiprates_export_spec.xls')

      gen = ExcelGenerator.new(expect)

      items = OptionType.all
      
      gen.export_with_associations(OptionType, items)

      File.exists?(expect).should be_true

    end
    
end