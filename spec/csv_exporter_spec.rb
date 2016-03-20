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
    results_clear( "*.csv" )
  end

  before(:each) do
    DataShift::MethodDictionary.clear
    DataShift::MethodDictionary.find_operators( Project )

    db_clear()    # todo read up about proper transactional fixtures
  end

  describe '#initialize' do
    it "should be able to create a new CSV exporter" do
      exporter = DataShift::CsvExporter.new( 'exp_rspec_csv_empty.csv' )

      expect(exporter).not_to be_nil
    end

    it "should throw if not active record objects" do
      exporter = DataShift::CsvExporter.new( 'exp_rspec_csv_empty.csv' )

      expect{ exporter.export([123.45]) }.to raise_error(ArgumentError)
    end
  end

  describe "#export" do
    let(:project) { create( :project ) }
    let(:expected_columns) { project.serializable_hash.keys }
    let(:expected_values) { project.serializable_hash.values.map &:to_s }

    before { project }

    it "should export collection of model objects to .xls file" do
      Project.create( :value_as_string	=> 'Value as String', :value_as_boolean => true,	:value_as_double => 75.672)

      expected = result_file('exp_project_collection_spec.csv')
      exporter = DataShift::CsvExporter.new( expected )
      count = Project.count
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

    it "should export a model object to csv file with custom delimeter" do
      expected = result_file('project_first_export_spec_with_custom_delimeter.csv')
      exporter = DataShift::CsvExporter.new( expected )

      exporter.export(Project.all[0])
      got_columns, got_values = CSV.read(expected)
      expect(expected_columns.count).to eq got_columns.count
      expect(expected_values.count).to eq got_values.count

      expect(expected_columns || got_columns).to eq expected_columns
      expect(expected_values || got_values).to eq expected_values

      exporter.export(Project.all[0], csv_delim: "§")
      got_headers, got_columns = CSV.read(expected, col_sep: "§")

      expect(expected_columns || got_columns).to eq expected_columns
      expect(expected_values || got_values).to eq expected_values

      exporter.export(Project.all[0], csv_delim: "£")
      got_headers, got_columns = CSV.read(expected, col_sep: "£")

      expect(expected_columns.count).to eq got_columns.count
      expect(expected_columns || got_columns).to eq expected_columns
      expect(expected_values || got_values).to eq expected_values
    end

    it "should export a model and result of method calls on it to csv file" do

      expected = result_file('project_with_methods_export_spec.csv')

      exporter = DataShift::CsvExporter.new( expected )

      exporter.export(Project.all, {:methods => [:multiply]})

      expect(File.exists?(expected)).to eq true

      File.foreach(expected) {}
      count = $.
      count.should == Project.count + 1
    end

  end

  describe "#export_with_assoiations" do
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
end
