# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Specs for CSV aspect of export
#
require File.dirname(__FILE__) + '/../spec_helper'

module DataShift

  describe 'CSV Exporter' do
    before(:all) do
      results_clear( '*.csv' )
    end

    include_context 'ClearThenManageProject'

    context 'simple project' do
      before(:each) do
        create( :project )
      end

      it 'should be able to create a new CSV exporter' do
        exporter = CsvExporter.new( 'exp_rspec_csv_empty.csv' )

        expect(exporter).not_to be_nil
      end

      it 'should throw if not active record objects' do
        exporter = DataShift::CsvExporter.new( 'exp_rspec_csv_empty.csv' )

        expect { exporter.export([123.45]) }.to raise_error(ArgumentError)
      end

      it 'should export collection of model objects to csv file', fail: true do
        expected = result_file('exp_project_collection_spec.csv')

        exporter = DataShift::CsvExporter.new( expected )

        exporter.export(Project.all)

        expect(File.exist?(expected)).to eq true

        puts "Can manually check file @ #{expected}"

        csv = CSV.read(expected)

        expect(csv[1]).to include Project.first.title

        expect(csv[0].index 'title').to_not be_nil
        expect(csv[0].index 'value_as_string').to_not be_nil

        File.foreach(expected) {}
        count = $INPUT_LINE_NUMBER
        expect(count).to eq Project.count + 1
      end

      it 'should handle bad params to export' do
        expected = result_file('project_first_export_spec.csv')

        exporter = DataShift::CsvExporter.new( expected )

        expect { exporter.export(nil) }.not_to raise_error

        expect { exporter.export([]) }.not_to raise_error

        puts "Can manually check file @ #{expected}"
      end

      it 'should export a model object to csv file' do
        expected = result_file('project_first_export_spec.csv')

        exporter = DataShift::CsvExporter.new( expected )

        exporter.export(Project.all[0])

        expect(File.exist?(expected)).to eq true

        puts "Can manually check file @ #{expected}"
      end

      it 'should export a model and result of method calls on it to csv file' do
        expected = result_file('project_with_methods_export_spec.csv')

        exporter = DataShift::CsvExporter.new( expected )

        exporter.export(Project.all, methods: [:multiply])

        expect(File.exist?(expected)).to eq true

        puts "Can manually check file @ #{expected}"

        File.foreach(expected) {}
        count = $INPUT_LINE_NUMBER
        expect(count).to eq Project.count + 1
      end

      it 'should enable removal of certain columns', duff: true do
        expected = result_file('project_remove_export_spec.csv')

        options = { remove: [:title, :value_as_integer] }

        exporter = DataShift::CsvExporter.new( expected )

        exporter.export(Project.all, options)

        expect(File.exist?(expected)).to eq true

        csv = CSV.read(expected)

        expect(csv[1]).to_not include Project.first.title

        expect(csv[0].index 'title').to be_nil
        expect(csv[0].index 'value_as_integer').to be_nil
        expect(csv[0].index 'value_as_string').to_not be_nil
      end

    end

    context 'with associations' do
      let(:basic_projects) { 7 }

      let(:expected) { result_file('exp_project_plus_assoc_export_spec.csv') }

      before(:each) do
        @user = create( :project_with_user ).user
        create_list(:project, basic_projects)
      end

      it 'should export a model and associations to a file' do
        gen = DataShift::CsvExporter.new(expected)

        gen.export_with_associations(Project, Project.all)

        expect(File.exist?(expected)).to eq true

        File.foreach(expected) {}
        count = $INPUT_LINE_NUMBER
        expect(count).to eq basic_projects + 2
      end

      it 'should include headers and association names in row 0' do
        gen = DataShift::CsvExporter.new(expected)

        gen.export_with_associations(Project, Project.all)

        expect(File.exist?(expected)).to eq true

        csv = CSV.read(expected)

        expect(csv[0][0]).to eq 'id'
        expect(csv[0]).to include 'owner'
        expect(csv[0]).to include 'user'

        user_inx = csv[0].index 'user'

        expect(user_inx).to be > -1
      end

      it 'should export model & associations to single row' do
        gen = DataShift::CsvExporter.new(expected)

        items = Project.all

        gen.export_with_associations(Project, items)

        csv = CSV.read(expected)

        user_header_inx = csv[0].index 'user'
        csv.shift # shift off headers

        expected_ids = items.collect { |p| p.id.to_s }
        ids = csv.collect { |r| r[0][0] }
        expect(ids).to eq expected_ids

        expect( csv[0][user_header_inx] ).to include "title => #{@user.title},first_name => #{@user.first_name}"
      end
    end
  end

end
