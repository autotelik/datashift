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

describe 'CSV Exporter' do

  before(:all) do
      
    # load our test model definitions - Project etc  
    require ifixture_file('test_model_defs')  
  
    db_connect( 'test_file' )    # , test_memory, test_mysql
   
    # handle migration changes or reset of test DB
    migrate_up

    results_clear()
  end
  
  before(:each) do
    DataShift::MethodDictionary.clear
    DataShift::MethodDictionary.find_operators( Project )
    
    db_clear()    # todo read up about proper transactional fixtures
    
    Project.create( :value_as_string	=> 'Value as String', :value_as_boolean => true,	:value_as_double => 75.672)
    Project.create( :value_as_string	=> 'Another Value as String', :value_as_boolean => false,	:value_as_double => 12)
     
  end
  
  it "should be able to create a new CSV exporter" do
    exporter = DataShift::CsvExporter.new( 'rspec_csv_empty.csv' )
      
    exporter.should_not be_nil
  end

  it "should throw if not active record objects" do
    exporter = DataShift::CsvExporter.new( 'rspec_csv_empty.csv' )
      
    expect{ exporter.export([123.45]) }.to raise_error(ArgumentError)
  end
  

  it "should export collection of model objects to .xls file" do

    expected = result_file('project_export_spec.csv')

    exporter = DataShift::CsvExporter.new( expected )
     
    count = Project.count 
    
    Project.create( :value_as_string	=> 'Value as String', :value_as_boolean => true,	:value_as_double => 75.672)
     
    Project.count.should == count + 1
    
    exporter.export(Project.all)
 
    expect(File.exists?(expected)).to eq true
      
    puts "Can manually check file @ #{expected}"
    
    File.foreach(expected) {}
    count = $.
    count.should == Project.count + 1
  end

  it "should handle bad params to export" do

    expected = result_file('project_first_export_spec.csv')

    exporter = DataShift::CsvExporter.new( expected )
    
    expect{ exporter.export(nil) }.not_to raise_error

    expect{ exporter.export([]) }.not_to raise_error
   
    puts "Can manually check file @ #{expected}"
  end
  
  it "should export a model object to csv file" do

    expected = result_file('project_first_export_spec.csv')

    exporter = DataShift::CsvExporter.new( expected )
    
    exporter.export(Project.all[0])
 
    expect(File.exists?(expected)).to eq true
      
    puts "Can manually check file @ #{expected}"
  end

  it "should export a model and result of method calls on it to csv file" do

    expected = result_file('project_with_methods_export_spec.csv')

    exporter = DataShift::CsvExporter.new( expected )
     
    exporter.export(Project.all, {:methods => [:multiply]})
 
    expect(File.exists?(expected)).to eq true
      
    puts "Can manually check file @ #{expected}"
    
    File.foreach(expected) {}
    count = $.
    count.should == Project.count + 1
  end
  
  it "should export a  model and associations to .xls file" do

    p = Project.create( :value_as_string	=> 'Value as String', :value_as_boolean => true,	:value_as_double => 75.672)

    p.milestones.create( :name => 'milestone_1', :cost => 23.45)
    
    expected = result_file('project_plus_assoc_export_spec.csv')

    gen = DataShift::CsvExporter.new(expected)

    gen.export_with_associations(Project, Project.all)

    expect(File.exists?(expected)).to eq true

    File.foreach(expected) {}
    count = $.
    count.should == Project.count + 1
    
  end


end