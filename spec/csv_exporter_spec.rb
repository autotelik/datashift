# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     Sept 2012
# License::   MIT
#
# Details::   Specs for CSV aspect of export
#
require File.dirname(__FILE__) + '/spec_helper'

require 'erb'
require 'csv_exporter'

describe 'CSV Loader' do

  before(:all) do
    
    db_connect( 'test_file' )    # , test_memory, test_mysql

    # load our test model definitions - Project etc
    require File.join($DataShiftFixturePath, 'test_model_defs')  
   
    # handle migration changes or reset of test DB
    migrate_up

    db_clear()    # todo read up about proper transactional fixtures
    results_clear()
  end
  
  before(:each) do
    MethodDictionary.clear
    MethodDictionary.find_operators( Project )
    
  end
  
  it "should be able to create a new CSV exporter" do
    generator = CsvExporter.new( 'rspec_csv_empty.csv' )
      
    generator.should_not be_nil
  end
  
  it "should export a model to csv file" do

    expect = result_file('project_export_spec.csv')

    gen = CsvExporter.new( expect )
    
    gen.export(Project)
 
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