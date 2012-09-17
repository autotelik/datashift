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
  end

  it "should include all associations in template .xls file from model" do

    expect= result_file('project_plus_assoc_template_spec.xls')

    gen = ExcelGenerator.new(expect)

    gen.generate_with_associations(Project)

    File.exists?(expect).should be_true

  end
    
    
  it "should enable us to exclude cetain associations in template .xls file from model" do

    expect= result_file('project_plus_some_assoc_template_spec.xls')

    gen = ExcelGenerator.new(expect)

    options = {:exclude => :milestones }
      
    gen.generate_with_associations(Project, options)

    File.exists?(expect).should be_true
      
    excel = Excel.new
    excel.open(expect)
      
    excel.each {|r| puts r.inspect }
      
  end
    
    
  it "should enable us to autosize columns in the .xls file" do

    expect= result_file('project_autosized_template_spec.xls')

    gen = ExcelGenerator.new(expect)

    options = {:autosize => true, :exclude => :milestones }
      
    gen.generate_with_associations(Project, options)

    File.exists?(expect).should be_true
      
    excel = Excel.new
    excel.open(expect)
      
    excel.each {|r| puts r.inspect }
      
  end
    
end
