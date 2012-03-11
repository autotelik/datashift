# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'

if(Guards::jruby?)
  require 'erb'
  require 'excel_generator'

  include DataShift

  describe 'Excel Generator' do

    before(:all) do
      db_connect( 'test_file' )    # , test_memory, test_mysql

      # load our test model definitions - Project etc
      require File.join($DataShiftFixturePath, 'test_model_defs')  
   
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
      generator = ExcelExporter.new( 'dummy.xls' )
      
      generator.should_not be_nil
    end
  
    it "should generate template .xls file from model" do

      expect = result_file('project_template_spec.xls')

      gen = ExcelExporter.new( expect )
    
      gen.generate(Project)
 
      File.exists?(expect).should be_true
      
      puts "Can manually check file @ #{expect}"
    end

    it "should export a simple model to .xls spreedsheet" do

      Project.create( :value_as_string	=> 'Value as Text', :value_as_boolean => true,	:value_as_double => 75.672)
      #001 Demo string	blah blah	2011-02-14	1.00	320.00

      expect= result_file('simple_export_spec.xls')

      gen = ExcelGenerator.new(expect)

      items = Project.all

      gen.export(items)

      File.exists?(expect).should be_true

    end

  end
else
  puts "WARNING: skipped excel_exporter_spec : Requires JRUBY - JExcelFile requires JAVA"
end # jruby