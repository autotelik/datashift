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

    results_clear()

    @klazz = Project
    @assoc_klazz = Category
  end
  
  before(:each) do
    MethodDictionary.clear
    MethodDictionary.find_operators( @klazz )
    MethodDictionary.find_operators( @assoc_klazz )
    
    db_clear()    # todo read up about proper transactional fixtures
        
    Project.create( :value_as_string	=> 'Value as String', :value_as_boolean => true,	:value_as_double => 75.672)
    Project.create( :value_as_string	=> 'Another Value as String', :value_as_boolean => false,	:value_as_double => 12)
     
    
  end
  
  it "should be able to create a new excel exporter" do
    generator = ExcelExporter.new( 'dummy.xls' )
      
    generator.should_not be_nil
  end
  
  it "should handle bad params to export" do

    expect = result_file('project_first_export_spec.csv')

    exporter = DataShift::ExcelExporter.new( expect )
    
    expect{ exporter.export(nil) }.not_to raise_error

    expect{ exporter.export([]) }.not_to raise_error
   
    puts "Can manually check file @ #{expect}"
  end
  
  it "should export model object to .xls file" do

    expected = result_file('project_first_export_spec.xls')

    gen = ExcelExporter.new( expected )
    
    gen.export(Project.all.first)
 
    expect(File.exists?(expected)).to eq true
      
    puts "Can manually check file @ #{expected}"
  end

  it "should export collection of model objects to .xls file" do

    expected = result_file('project_export_spec.xls')

    gen = ExcelExporter.new( expected )
    
    gen.export(Project.all)
 
    expect( File.exists?(expected)).to eq true
      
    puts "Can manually check file @ #{expected}"
  end
  
  it "should export a  model and associations to .xls file" do

    Project.create( :value_as_string	=> 'Value as Text', :value_as_boolean => true,	:value_as_double => 75.672)

    expected = result_file('project_plus_assoc_export_spec.xls')

    gen = ExcelExporter.new(expected)

    items = Project.all

    gen.export_with_associations(Project, items)

    expect(File.exists?(expected)).to eq true

  end

end
