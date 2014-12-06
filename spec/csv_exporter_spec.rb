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

  include_context "ActiveRecordTestModelsConnected"

  before(:all) do
    results_clear( "*.csv" )
  end

  before(:each) do
    DataShift::MethodDictionary.clear
    DataShift::MethodDictionary.find_operators( Project )

    db_clear()    # todo read up about proper transactional fixtures
  end

  context 'simple project' do

    before(:each) do
      create( :project )
    end

    it "should be able to create a new CSV exporter" do
      exporter = DataShift::CsvExporter.new( 'exp_rspec_csv_empty.csv' )

      exporter.should_not be_nil
    end

    it "should throw if not active record objects" do
      exporter = DataShift::CsvExporter.new( 'exp_rspec_csv_empty.csv' )

      expect{ exporter.export([123.45]) }.to raise_error(ArgumentError)
    end


    it "should export collection of model objects to .xls file", :fail => true do

      expected = result_file('exp_project_collection_spec.csv')

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

  end

  it "should export a model and associations to csv" do

    create( :project_user )
    create_list(:project, 7)

    expected = result_file('exp_project_plus_assoc_export_spec.csv')

    gen = DataShift::CsvExporter.new(expected)

    items = Project.all

    gen.export_with_associations(Project, items)

    File.foreach(expected) {}
    count = $.
    count.should == items.size + 1

    expect(File.exists?(expected)).to eq true

    csv = CSV.read(expected)

    expect(csv[0]).to include 'owner'
    expect(csv[0]).to include 'user'

    user_inx = csv[0].index 'user'

    expect(user_inx).to be > -1

    expect( csv[1][user_inx] ).to include 'mr'
  end

end