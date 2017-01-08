# encoding: utf-8

# The above is required for JRuby to handle the line :
#     describe "with § as delim" do
# Without this Jruby throws - invalid multibyte char (US-ASCII)
#
# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Specs for CSV aspect of export
#
require_relative '../../spec_helper'

module DataShift

  describe CsvExporter do

    before(:all) do
      results_clear( '*.csv' )
    end

    before(:each) do
      DataShift::Exporters::Configuration.reset
    end

    let(:exporter) { CsvExporter.new }

    include_context 'ClearThenManageProject'

    describe '#initialize' do
      it 'should be able to create a new CSV exporter' do
        expect(exporter).not_to be_nil
      end

      it 'should throw if not active record objects' do
        expect { exporter.export('exp_rspec_csv_empty.csv', [123.45]) }.to raise_error(ArgumentError)
      end
    end

    describe "#export" do

      let(:project) { create( :project ) }
      let(:expected_columns) { project.serializable_hash.keys }
      let(:expected_values) { project.serializable_hash.values.map &:to_s }

      before {
        project
      }

      it 'should export collection of model objects to csv file', fail: true do
        expected = result_file('exp_project_collection_spec.csv')

        exporter.export(expected, Project.all)

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

        expect { exporter.export(expected, nil) }.not_to raise_error

        expect { exporter.export(expected, []) }.not_to raise_error
      end

      it 'should export a model object to csv file' do
        expected = result_file('project_first_export_spec.csv')

        exporter.export(expected, Project.all[0])

        expect(File.exist?(expected)).to eq true

        puts "Can manually check file @ #{expected}"
      end


      shared_examples "csv exporter with custom delimeter" do

        it "should export a model object to csv file with custom delimeter" do
          exporter.export(expected, Project.all, csv_delim: csv_delim)

          got_columns, got_values = CSV.read(expected, col_sep: csv_delim)

          expect(expected_columns).to eq got_columns

          expect(expected_columns.count).to eq got_columns.count
          expect(expected_values.count).to eq got_values.count
        end
      end

      describe "with , as delim" do
        it_behaves_like "csv exporter with custom delimeter" do
          let(:csv_delim) { ',' }
          let(:expected) { result_file("project_export_spec_with_custom_delim_#{csv_delim}.csv") }
        end
      end


      describe "with § as delim" do # Jruby throws - invalid multibyte char (US-ASCII)
        it_behaves_like "csv exporter with custom delimeter" do
          let(:csv_delim) { '§' }
          let(:expected) { result_file("project_export_spec_with_custom_delim_#{csv_delim}.csv") }
        end
      end

      describe "with £ as delim" do
        it_behaves_like "csv exporter with custom delimeter" do
          let(:csv_delim) { '£' }
          let(:expected) { result_file("project_export_spec_with_custom_delim_#{csv_delim}.csv") }
        end
      end

      it 'should export a model and result of method calls on it to csv file' do
        expected = result_file('project_with_methods_export_spec.csv')

        exporter.export(expected, Project.all, methods: [:multiply])

        expect(File.exist?(expected)).to eq true

        File.foreach(expected) {}
        count = $INPUT_LINE_NUMBER
        expect(count).to eq Project.count + 1
      end

      it 'should enable removal of certain columns' do
        expected = result_file('project_remove_export_spec.csv')

        DataShift::Configuration.call.remove_columns = [:title, :value_as_integer]

        exporter.export(expected, Project.all)

        expect(File.exist?(expected)).to eq true

        csv = CSV.read(expected)

        expect(csv[1]).to_not include Project.first.title

        expect(csv[0].index 'title').to be_nil
        expect(csv[0].index 'value_as_integer').to be_nil
        expect(csv[0].index 'value_as_string').to_not be_nil
      end

    end

    context 'with associations' do
      let(:project_create_count) { 7 }

      let(:expected) { result_file('exp_project_plus_assoc_export_spec.csv') }

      before(:each) do
        @user = create( :project_with_user ).user
        create_list(:project, project_create_count)
      end

      before(:each) do
        DataShift::Configuration.reset

        DataShift::Configuration.configure do |config|
          config.with = [:all]
        end
      end

      it 'should export a model and associations to a file' do
        expect(Project.count).to be > project_create_count
        exporter.export_with_associations(expected, Project, Project.all)

        expect(File.exist?(expected)).to eq true

        File.foreach(expected) {}
        count = $INPUT_LINE_NUMBER
        expect(count).to eq Project.count + 1
      end

      it 'should include headers and association names in row 0' do
        exporter.export_with_associations(expected, Project, Project.all)

        expect(File.exist?(expected)).to eq true

        csv = CSV.read(expected)

        expect(csv[0][0]).to eq 'id'
        expect(csv[0]).to include 'owner'
        expect(csv[0]).to include 'user'

        user_inx = csv[0].index 'user'

        expect(user_inx).to be > -1
      end

      it 'should export model & associations to single row' do

        exporter.export_with_associations(expected, Project, Project.all)

        csv = CSV.read(expected)

        user_header_inx = csv[0].index 'user'
        csv.shift # shift off headers

        expected_ids = Project.all.collect { |p| p.id.to_s }
        ids = csv.collect { |r| r[0][0] }
        expect(ids).to eq expected_ids

        expect( csv[0][user_header_inx] ).to include "title: #{@user.title},first_name: #{@user.first_name}"
      end

      it 'should export a model and assocs in json to .xls file' do

        expected = result_file('project_and_assoc_in_json_export.csv')

        DataShift::Exporters::Configuration.configure do |config|
          config.json = true
        end

        exporter.export_with_associations(expected, Project, Project.all)

        csv = CSV.read(expected)

        user_header_inx = csv[0].index 'user'
        csv.shift # shift off headers

        expect( csv[0][user_header_inx] ).to include "title: #{@user.title},first_name: #{@user.first_name}"
      end

    end
  end

end
