# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'

 
require 'erb'
require 'excel_exporter'

include DataShift

describe 'Excel Exporter' do

  before(:all) do
      
    # load our test model definitions - Project etc  
    require ifixture_file('test_model_defs')  
  
    db_connect( 'test_file' )    # , test_memory, test_mysql
   
    # handle migration changes or reset of test DB
    migrate_up

    db_clear()    # todo read up about proper transactional fixtures
    results_clear()

    @klazz = Project
    @assoc_klazz = Category
  end
  
  before(:each) do
    MethodDictionary.clear
    MethodDictionary.find_operators( @klazz )
    MethodDictionary.find_operators( @assoc_klazz )
  end
  
  it "should be able to create a new excel exporter" do
    generator = ExcelExporter.new( 'dummy.xls' )
      
    generator.should_not be_nil
  end
  
  it "should export a model to .xls file" do

    expect = result_file('project_export_spec.xls')

    gen = ExcelExporter.new( expect )
    
    gen.export(Project.all)
 
    File.exists?(expect).should be_true
      
    puts "Can manually check file @ #{expect}"
  end

  it "should export a  model and associations to .xls file" do

    Project.create( :value_as_string	=> 'Value as Text', :value_as_boolean => true,	:value_as_double => 75.672)

    expect= result_file('project_plus_assoc_export_spec.xls')

    gen = ExcelExporter.new(expect)

    items = Project.all

    gen.export_with_associations(Project, items)

    File.exists?(expect).should be_true

  end

end
