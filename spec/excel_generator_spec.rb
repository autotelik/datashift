# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'

require 'erb'
require 'excel_generator'

include DataShift

describe 'Excel Generator' do

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
  
  it "should be able to create a new excel generator" do
    generator = ExcelGenerator.new( 'dummy.xls' )
      
    generator.should_not be_nil
  end
  
  it "should generate template .xls file from model" do

    expect = result_file('project_template_spec.xls')

    gen = ExcelGenerator.new( expect )
    
    gen.generate(Project)
 
    File.exists?(expect).should be_true
      
    puts "Can manually check file @ #{expect}"
    
    excel = Excel.new
    excel.open(expect)
    
    excel.worksheets.should have(1).items
    
    excel.worksheet(0).name.should == 'Project'
      
    headers = excel.worksheets[0].row(0)
    
    [ "title", "value_as_string", "value_as_text", "value_as_boolean", "value_as_datetime", "value_as_integer", "value_as_double"].each do |check|
      headers.include?(check).should == true
    end
  end

  # has_one  :owner
  # has_many :milestones
  # has_many :loader_releases
  # has_many :versions, :through => :loader_releases
  # has_and_belongs_to_many :categories
  
  it "should include all associations in template .xls file from model" do

    expect= result_file('project_plus_assoc_template_spec.xls')

    gen = ExcelGenerator.new(expect)

    gen.generate_with_associations(Project)

    File.exists?(expect).should be_true

    excel = Excel.new
    excel.open(expect)
    
    excel.worksheets.should have(1).items
    
    excel.worksheet(0).name.should == 'Project'
      
    headers = excel.worksheets[0].row(0)
    
    ["owner", "milestones", "loader_releases", "versions", "categories"].each do |check|
      headers.include?(check).should == true
    end
  end
   
      
  it "should enable us to exclude associations by type in template .xls file", :fail => true do

    expect= result_file('project_plus_some_assoc_template_spec.xls')

    gen = ExcelGenerator.new(expect)

    options = {:exclude => :has_many }
      
    gen.generate_with_associations(Project, options)

    File.exists?(expect).should be_true, "Failed to find expected result file #{expect}"
      
    excel = Excel.new
    excel.open(expect)
    
    excel.worksheets.should have(1).items
    
    excel.worksheet(0).name.should == 'Project'
      
    headers = excel.worksheets[0].row(0)
    
    headers.include?('title').should == true
    headers.include?('owner').should == true
    
    ["milestones", "loader_releases", "versions", "categories"].each do |check|
      headers.should_not include check
    end
 
  end
  
    
  it "should enable us to exclude certain associations in template .xls file ", :fail => true do

    expect= result_file('project_plus_some_assoc_template_spec.xls')

    gen = ExcelGenerator.new(expect)

    options = {:remove => [:milestones, :versions] }
      
    gen.generate_with_associations(Project, options)

    File.exists?(expect).should be_true, "Failed to find expected result file #{expect}"
      
    excel = Excel.new
    excel.open(expect)
    
    excel.worksheets.should have(1).items
    
    excel.worksheet(0).name.should == 'Project'
      
    headers = excel.worksheets[0].row(0)

    ["title", "loader_releases", "owner", "categories"].each do |check|
      headers.should include check
    end
    

    ["milestones",  "versions", ].each do |check|
      headers.should_not include check
    end
    
  end
    
    
   it "should enable us to remove standard rails feilds from template .xls file ", :fail => true do

    expect= result_file('project_plus_some_assoc_template_spec.xls')

    gen = ExcelGenerator.new(expect)

    options = {:remove_rails => true}
      
    gen.generate_with_associations(Project, options)

    File.exists?(expect).should be_true, "Failed to find expected result file #{expect}"
      
    excel = Excel.new
    excel.open(expect)
    
    excel.worksheets.should have(1).items
    
    excel.worksheet(0).name.should == 'Project'
      
    headers = excel.worksheets[0].row(0)

    ["id", "updated_at", "created_at"].each do |check|
      headers.should_not include check
    end
    
    
  end
  
  it "should enable us to autosize columns in the .xls file" do

    expect= result_file('project_autosized_template_spec.xls')

    gen = ExcelGenerator.new(expect)

    options = {:autosize => true, :exclude => :milestones }
      
    gen.generate_with_associations(Project, options)

    File.exists?(expect).should be_true
      
    excel = Excel.new
    excel.open(expect)
      
  end
    
end
