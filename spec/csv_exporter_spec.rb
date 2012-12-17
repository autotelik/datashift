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
    MethodDictionary.clear
    MethodDictionary.find_operators( Project )
    
    db_clear()    # todo read up about proper transactional fixtures
  end
  
  it "should be able to create a new CSV exporter" do
    generator = CsvExporter.new( 'rspec_csv_empty.csv' )
      
    generator.should_not be_nil
  end
  
  it "should export a model to csv file" do

    expect = result_file('project_export_spec.csv')

    exporter = CsvExporter.new( expect )
     
    Project.create( :value_as_string	=> 'Value as String', :value_as_boolean => true,	:value_as_double => 75.672)
     
    exporter.export(Project.all)
 
    File.exists?(expect).should be_true
      
    puts "Can manually check file @ #{expect}"
    
    File.foreach(expect) {}
    count = $.
    count.should == Project.count + 1
  end

  it "should export a model and result of method calls on it to csv file" do

    expect = result_file('project_with_methods_export_spec.csv')

    exporter = CsvExporter.new( expect )
     
    Project.create( :value_as_string	=> 'Value as String', :value_as_boolean => true,	:value_as_double => 75.672)
    Project.create( :value_as_string	=> 'Another Value as String', :value_as_boolean => false,	:value_as_double => 12)
     
    exporter.export(Project.all, {:methods => [:multiply]})
 
    File.exists?(expect).should be_true
      
    puts "Can manually check file @ #{expect}"
    
    File.foreach(expect) {}
    count = $.
    count.should == Project.count + 1
  end
  
  it "should export a  model and associations to .xls file" do

    p = Project.create( :value_as_string	=> 'Value as String', :value_as_boolean => true,	:value_as_double => 75.672)

    p.milestones.create( :name => 'milestone_1', :cost => 23.45)
    
    expect= result_file('project_plus_assoc_export_spec.csv')

    gen = CsvExporter.new(expect)

    gen.export_with_associations(Project, Project.all)

    File.exists?(expect).should be_true

    File.foreach(expect) {}
    count = $.
    count.should == Project.count + 1
    
  end


end