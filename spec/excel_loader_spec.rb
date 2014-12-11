# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'

require 'erb'
require 'excel_loader'

include DataShift

describe 'Excel Loader' do

 # include_context "ActiveRecordTestModelsConnected"

  before(:each) do
  end


  before(:each) do
    create_list(:category, 5)
  end

  context 'loader creates new records' do

    it "should be able to create a new excel loader and load object" do
      loader = ExcelLoader.new( Project)

      loader.load_object.should_not be_nil
      loader.load_object.should be_is_a(Project)
      expect(loader.load_object.new_record?).to eq true
    end

    it "should process a simple .xls spreedsheet" do

      loader = ExcelLoader.new(Project)

      count = Project.count
      loader.perform_load ifixture_file('SimpleProjects.xls')

      loader.loaded_count.should == (Project.count - count)
    end

    it "should process multiple associations from single column", :fail => true do

      DataShift::MethodDictionary.find_operators( Category )

      DataShift::MethodDictionary.build_method_details( Category )

      expect(Project.find_by_title('001')).to be_nil

      count = Project.count

      puts "COUNT #{count}"

      loader = ExcelLoader.new(Project)

      loader.perform_load( ifixture_file('ProjectsSingleCategories.xls') )

      expect(loader.loaded_count).to eq 4

      loader.loaded_count.should == (Project.count - count)

      {'001' => 2, '002' => 1, '003' => 3, '099' => 0 }.each do|title, expected|
        project = Project.find_by_title(title)

        puts project.categories.inspect

        project.should_not be_nil

        expect(project.categories.size).to eq expected
      end
    end

    it "should process multiple associations in excel spreedsheet" do

      loader = ExcelLoader.new(Project)

      count = Project.count
      loader.perform_load( ifixture_file('ProjectsMultiCategories.xls' ))

      loader.loaded_count.should == (Project.count - count)

      {'004' => 3, '005' => 1, '006' => 0, '007' => 1 }.each do|title, expected|
        project = Project.find_by_title(title)

        project.should_not be_nil

        expect(project.categories.size).to eq expected
      end

    end

    it "should process multiple associations with lookup specified in column from excel spreedsheet" do

      loader = ExcelLoader.new(Project)

      count = Project.count
      loader.perform_load( ifixture_file('ProjectsMultiCategoriesHeaderLookup.xls'))

      loader.loaded_count.should == (Project.count - count)
      loader.loaded_count.should > 3

      {'004' => 4, '005' => 1, '006' => 0, '007' => 1 }.each do|title, expected|
        project = Project.find_by_title(title)

        project.should_not be_nil

        expect(project.categories.size).to eq expected
      end

    end

    it "should process excel spreedsheet with extra undefined columns" do
      loader = ExcelLoader.new(Project)
      lambda {loader.perform_load( ifixture_file('BadAssociationName.xls') ) }.should_not raise_error
    end

    it "should NOT process excel spreedsheet with extra undefined columns when strict mode" do
      loader = ExcelLoader.new(Project)
      expect {loader.perform_load( ifixture_file('BadAssociationName.xls'), :strict => true)}.to raise_error(MappingDefinitionError)
    end

    it "should raise an error when mandatory columns missing" do
      loader = ExcelLoader.new(Project)
      expect {loader.perform_load(ifixture_file('ProjectsMultiCategories.xls'), :mandatory => ['not_an_option', 'must_be_there'])}.to raise_error(DataShift::MissingMandatoryError)
    end

  end

  context 'update existing records' do
  end

  context 'external configuration of loader' do

    it "should provide facility to set default values", :focus => true do
      loader = ExcelLoader.new(Project)

      populator = loader.populator

      populator.set_default_value('value_as_string', 'some default text' )
      populator.set_default_value('value_as_double', 45.467 )
      populator.set_default_value('value_as_boolean', true )

      texpected = Time.now.to_s(:db)

      populator.set_default_value('value_as_datetime', texpected )

      #value_as_string	Value as Text	value as datetime	value_as_boolean	value_as_double	category

      loader.perform_load(ifixture_file('ProjectsSingleCategories.xls'))

      p = Project.find_by_title( '099' )

      p.should_not be_nil

      p.value_as_string.should == 'some default text'
      p.value_as_double.should == 45.467
      p.value_as_boolean.should == true
      p.value_as_datetime.to_s(:db).should == texpected

      # expected: "2012-09-17 10:00:52"
      # got: Mon Sep 17 10:00:52 +0100 2012 (using ==)

      p_no_defs = Project.first

      p_no_defs.value_as_string.should_not == 'some default text'
      p_no_defs.value_as_double.should_not == 45.467
      p_no_defs.value_as_datetime.should_not == texpected

    end

    it "should provide facility to set pre and post fix values" do
      loader = ExcelLoader.new(Project)

      loader.populator.set_prefix('value_as_string', 'myprefix' )
      loader.populator.set_postfix('value_as_string', 'my post fix' )

      #value_as_string	Value as Text	value as datetime	value_as_boolean	value_as_double	category

      loader.perform_load( ifixture_file('ProjectsSingleCategories.xls'))

      p = Project.find_by_title( '001' )

      p.should_not be_nil

      p.value_as_string.should == 'myprefixDemo stringmy post fix'
    end

    it "should provide facility to set default values via YAML configuration", :excel => true do
      loader = ExcelLoader.new(Project)

      loader.configure_from( ifixture_file('ProjectsDefaults.yml') )


      loader.perform_load( ifixture_file('ProjectsSingleCategories.xls') )

      p = Project.find_by_title( '099' )

      p.should_not be_nil

      p.value_as_string.should == "Default Project Value"
    end


    it "should provide facility to over ride values via YAML configuration", :excel => true do
      loader = ExcelLoader.new(Project)

      loader.configure_from( ifixture_file('ProjectsDefaults.yml') )


      loader.perform_load( ifixture_file('ProjectsSingleCategories.xls') )

      Project.all.each {|p| p.value_as_double.should == 99.23546 }
    end



    it "should provide facility to over ride values via YAML configuration", :yaml => true do
      loader = ExcelLoader.new(Project)

      expect(Project.count).to eq 0

      loader.configure_from( ifixture_file('ProjectsDefaults.yml') )


      loader.perform_load( ifixture_file('ProjectsSingleCategories.xls') )

      Project.all.each do |p|
        expect(p.value_as_double).to be_a BigDecimal
        expect(p.value_as_double).to eq 99.23546
      end
    end


  end

end
