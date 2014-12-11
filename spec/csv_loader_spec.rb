# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for CSV aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'

require 'erb'
require 'csv_loader'

include DataShift

describe 'Csv Loader' do

  before(:each) do
    DataShift::MethodDictionary.clear

    @method_mapper = DataShift::MethodMapper.new
  end


  before(:each) do

    %w{category_001 category_002 category_003 category_004 category_005}.each do |cat|
      Category.find_or_create_by(reference: cat)
    end


  end

  it "should be able to create a new csv loader and load object" do
    loader = CsvLoader.new(Project)

    loader.load_object.should_not be_nil
    loader.load_object.should be_is_a(Project)
    expect(loader.load_object.new_record?).to eq true
  end

  it "should process a simple .csv spreedsheet" do

    loader = CsvLoader.new(Project)

    count = Project.count
    loader.perform_load ifixture_file('csv/SimpleProjects.csv')

    loader.loaded_count.should == (Project.count - count)
  end

  it "should process multiple associationss from single column" do

    DataShift::MethodDictionary.find_operators( Category )

    DataShift::MethodDictionary.build_method_details( Category )

    Project.find_by_title('001').should be_nil
    count = Project.count

    loader = CsvLoader.new(Project)

    loader.perform_load( ifixture_file('csv/ProjectsSingleCategories.csv') )

    loader.loaded_count.should be > 3
    loader.loaded_count.should == (Project.count - count)

    {'001' => 2, '002' => 1, '003' => 3, '099' => 0 }.each do|title, expected|
      project = Project.find_by_title(title)

      project.should_not be_nil
      #puts "#{project.inspect} [#{project.categories.size}]"

      expect(project.categories.size).to eq expected
    end
  end

  it "should process multiple associations in csv file" do

    loader = CsvLoader.new(Project)

    count = Project.count
    loader.perform_load( ifixture_file('csv/ProjectsMultiCategories.csv' ))

    loader.loaded_count.should == (Project.count - count)

    {'004' => 3, '005' => 1, '006' => 0, '007' => 1 }.each do|title, expected|
      project = Project.find_by_title(title)

      project.should_not be_nil

      expect(project.categories.size).to eq expected
    end

  end

  it "should process multiple associations with lookup specified in column from excel spreedsheet", :fail => true do

    loader = CsvLoader.new(Project)

    count = Project.count
    loader.perform_load( ifixture_file('csv/ProjectsMultiCategoriesHeaderLookup.csv'))

    loader.loaded_count.should == (Project.count - count)
    loader.loaded_count.should > 3

    {'004' => 4, '005' => 1, '006' => 0, '007' => 1 }.each do|title, expected|
      project = Project.find_by_title(title)

      project.should_not be_nil

       expect(project.categories.size).to eq expected
    end

  end

  it "should process excel spreedsheet with extra undefined columns" do
    loader = CsvLoader.new(Project)
    lambda {loader.perform_load( ifixture_file('csv/BadAssociationName.csv') ) }.should_not raise_error
  end

  it "should NOT process excel spreedsheet with extra undefined columns when strict mode" do
    loader = CsvLoader.new(Project)
    expect {loader.perform_load( ifixture_file('csv/BadAssociationName.csv'), :strict => true)}.to raise_error(MappingDefinitionError)
  end

  it "should raise an error when mandatory columns missing" do
    loader = CsvLoader.new(Project)
    expect {loader.perform_load(ifixture_file('csv/ProjectsMultiCategories.csv'), :mandatory => ['not_an_option', 'must_be_there'])}.to raise_error(DataShift::MissingMandatoryError)
  end

  it "should provide facility to set default values", :focus => true do
    loader = CsvLoader.new(Project)

    populator = loader.populator

    populator.set_default_value('value_as_string', 'some default text' )
    populator.set_default_value('value_as_double', 45.467 )
    populator.set_default_value('value_as_boolean', true )

    texpected = Time.now.to_s(:db)

    populator.set_default_value('value_as_datetime', texpected )

    #value_as_string	Value as Text	value as datetime	value_as_boolean	value_as_double	category

    loader.perform_load(ifixture_file('csv/ProjectsSingleCategories.csv'))

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
    loader = CsvLoader.new(Project)

    loader.populator.set_prefix('value_as_string', 'myprefix' )
    loader.populator.set_postfix('value_as_string', 'my post fix' )

    #value_as_string	Value as Text	value as datetime	value_as_boolean	value_as_double	category

    loader.perform_load( ifixture_file('csv/ProjectsSingleCategories.csv'))

    p = Project.find_by_title( '001' )

    p.should_not be_nil

    p.value_as_string.should == 'myprefixDemo stringmy post fix'
  end

  it "should provide facility to set default values via YAML configuration", :csv => true do
    loader = CsvLoader.new(Project)

    loader.configure_from( ifixture_file('ProjectsDefaults.yml') )


    loader.perform_load( ifixture_file('csv/ProjectsSingleCategories.csv') )

    p = Project.find_by_title( '099' )

    p.should_not be_nil

    p.value_as_string.should == "Default Project Value"
  end


  it "should provide facility to over ride values via YAML configuration", :csv => true do
    loader = CsvLoader.new(Project)

    loader.configure_from( ifixture_file('ProjectsDefaults.yml') )


    loader.perform_load( ifixture_file('csv/ProjectsSingleCategories.csv') )

    Project.all.each {|p| p.value_as_double.should == 99.23546 }
  end


end
