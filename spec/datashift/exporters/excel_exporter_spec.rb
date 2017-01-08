# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require_relative '../../spec_helper'

require 'erb'
require 'excel_exporter'

module  DataShift

  describe 'Excel Exporter' do
    include_context 'ClearThenManageProject'

    before(:all) do
      results_clear( '*.xls' )
    end

    before(:each) do
      DataShift::Exporters::Configuration.reset

      DataShift::Configuration.reset
    end

    let(:exporter) { ExcelExporter.new }

    it 'should be able to create a new excel exporter' do
      expect(exporter).to_not be_nil
    end

    it 'should handle bad params to export' do
      expect = result_file('project_first_export_spec.csv')

      expect { exporter.export(expect, nil) }.not_to raise_error

      expect { exporter.export(expect, []) }.not_to raise_error

      puts "Can manually check file @ #{expect}"
    end

    context 'export model only' do
      let(:expected_projects)   { 7 }

      before(:each) do
        create_list(:project, expected_projects)
      end

      it 'should export model object to .xls file' do
        expected = result_file('exp_project_first_export.xls')

        exporter.export(expected, Project.all.first)

        expect(File.exist?(expected)).to eq true
      end

      it 'should export model attributes as headers' do
        expected = result_file('exp_project_export.xls')

        exporter.export(expected, Project.all)

        excel = Excel.new
        excel.open(expected)

        expect(excel.row(0)).to match Project.columns.collect(&:name)
      end

      it 'should export collection of model objects to .xls file' do
        expected = result_file('exp_project_export.xls')

        exporter.export(expected, Project.all)

        excel = Excel.new
        excel.open(expected)

        expect(excel.num_rows).to eq expected_projects + 1
      end
    end

    context 'project with associations' do
      let(:expected_projects) { 7 }

      before(:each) do

        create( :project_with_milestones, milestones_count: 4 )

        create_list(:project, expected_projects)

        create( :project_with_user )

        DataShift::Configuration.configure do |config|
          config.with = :all
        end
      end

      it 'should include associations in headers', duff: true do
        expected = result_file('exp_project_assoc_headers.xls')

        exporter.export_with_associations(expected, Project, Project.all)

        expect(File.exist?(expected)).to eq true

        excel = Excel.new
        excel.open(expected)

        expect(excel.row(0)).to include 'owner'
        expect(excel.row(0)).to include 'user'
      end

      it 'should export a model and associations to .xls file' do
        expected = result_file('exp_project_plus_assoc.xls')

        exporter.export_with_associations(expected, Project, Project.all)

        expect(File.exist?(expected)).to eq true

        excel = Excel.new
        excel.open(expected)

        expected_rows = Project.count + 1
        last_idx = Project.count

        expect(excel.num_rows).to eq expected_rows

        user_inx = excel.row(0).index 'user'
        owner_inx = excel.row(0).index 'owner'

        expect(user_inx).to be > -1
        expect(owner_inx).to be > -1

        # not all rows have an Owner
        expect( excel[3, owner_inx] ).to be_nil
        expect( excel[3, user_inx] ).to include "title: mr,first_name: ben}"

        # project_with_user has real associated user data
        expect( excel[last_idx, user_inx] ).to include 'mr'

        owner_idx = excel.row(0).index 'owner'

        expect(owner_idx).to be > -1

        expect( excel[last_idx, owner_idx] ).to include '10000.23'
      end

      it 'should export associations in hash format by default to .xls file', fail: true do

        expected = result_file('project_and_assoc_in_hash_export.xls')

        exporter.export_with_associations(expected, Project, Project.all)

        expect(File.exist?(expected)).to eq true

        excel = Excel.new
        excel.open(expected)

        row_with_milestone_data = find_row_with_milestone(excel)

        expect( row_with_milestone_data ).to include ColumnPacker.multi_assoc_delim
        expect( row_with_milestone_data ).to include '{'
        expect( row_with_milestone_data ).to match(/name: milestone/)
        expect( row_with_milestone_data ).to match(/project_id: \d+/)
      end

      it 'should export a model and  assocs in json to .xls file' do

        expected = result_file('project_and_assoc_in_json_export.xls')

        DataShift::Exporters::Configuration.configure do |config|
          config.json = true
        end

        exporter.export_with_associations(expected, Project, Project.all)

        expect(File.exist?(expected)).to eq true

        excel = Excel.new
        excel.open(expected)

        row_with_milestone_data = find_row_with_milestone(excel)

        expect( row_with_milestone_data ).to include '['
        expect( row_with_milestone_data ).to match(/name\":\"milestone/)
        expect( row_with_milestone_data ).to match(/"project_id":\d+/)
      end

      def find_row_with_milestone(excel)
        milestone_inx = excel.row(0).index 'milestones'

        idx_milestone_data = 1

        while(idx_milestone_data < Project.count) do
          break if excel[idx_milestone_data, milestone_inx].to_s.present?
          idx_milestone_data += 1
        end

        excel[idx_milestone_data, milestone_inx].to_s
      end
    end
  end
end
