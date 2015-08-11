# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/../spec_helper'

require 'erb'
require 'excel_exporter'

module  DataShift

  describe 'Excel Exporter' do

    include_context 'ClearThenManageProject'

    before(:all) do
      results_clear( '*.xls' )
    end

    it 'should be able to create a new excel exporter' do
      generator = ExcelExporter.new( 'exp_dummy.xls' )

      expect(generator).to_not be_nil
    end

    it 'should handle bad params to export' do
      expect = result_file('project_first_export_spec.csv')

      exporter = DataShift::ExcelExporter.new( expect )

      expect { exporter.export(nil) }.not_to raise_error

      expect { exporter.export([]) }.not_to raise_error

      puts "Can manually check file @ #{expect}"
    end

    context 'export model only' do

      let(:expected_projects)   { 7 }

      before(:each) do
        create_list(:project, expected_projects)
      end

      it 'should export model object to .xls file' do
        expected = result_file('exp_project_first_export.xls')

        gen = ExcelExporter.new( expected )

        gen.export(Project.all.first)

        expect(File.exist?(expected)).to eq true

        puts "Can manually check file @ #{expected}"
      end

      it 'should export collection of model objects to .xls file' do

        expected = result_file('exp_project_export.xls')

        gen = ExcelExporter.new( expected )

        gen.export(Project.all)

        expect( File.exist?(expected)).to eq true

        excel = Excel.new
        excel.open(expected)

        expect(excel.num_rows).to eq expected_projects + 1
      end
    end

    context 'project with associations' do

      let(:expected_projects)   { 7 }

      before(:each) do
        create_list(:project, expected_projects)
      end

      it 'should include associations in headers' do
        create( :project_with_user )

        expected = result_file('exp_project_plus_assoc.xls')

        gen = ExcelExporter.new(expected)

        items = Project.all

        gen.export_with_associations(Project, items)

        expect(File.exist?(expected)).to eq true

        excel = Excel.new
        excel.open(expected)

        expect(excel.row(0)).to include 'owner'
        expect(excel.row(0)).to include 'user'
      end

      it 'should export a model and associations to .xls file' do
        create( :project_with_user )

        expected = result_file('exp_project_plus_assoc.xls')

        gen = ExcelExporter.new(expected)

        items = Project.all

        gen.export_with_associations(Project, items)

        expect(File.exist?(expected)).to eq true

        excel = Excel.new
        excel.open(expected)

        expected_rows = Project.count + 1
        last_idx = Project.count

        expect(excel.num_rows).to eq expected_rows

        user_inx = excel.row(0).index 'user'

        expect(user_inx).to be > -1

        expect( excel[1, user_inx] ).to be_nil

        # project_with_user has real associated user data
        expect( excel[last_idx, user_inx] ).to include 'mr'

        owner_idx= excel.row(0).index 'owner'

        expect(owner_idx).to be > -1

        expect( excel[last_idx, owner_idx] ).to include '10000.23'
      end

      it 'should export a model and has_many assocs to .xls file', fail: true do
        create( :project_with_user )
        create( :project_with_milestones, milestones_count: 4 )

        expected = result_file('project_and_has_many_assoc_export.xls')

        gen = ExcelExporter.new(expected)

        items = Project.all

        gen.export_with_associations(Project, items)

        expect(File.exist?(expected)).to eq true

        excel = Excel.new
        excel.open(expected)

        expect(excel.row(0)).to include 'owner'
        expect(excel.row(0)).to include 'user'

        expect(excel.num_rows).to eq Project.count + 1

        milestone_inx = excel.row(0).index 'milestones'

        expect(milestone_inx).to be > -1

        # These tests very flakey - better way to find row rather than rely on idx??
        last_idx = Project.count

        # project_with_milestones has real associated user data
        expect( excel[last_idx, milestone_inx].to_s ).to include Delimiters.multi_assoc_delim
        expect( excel[last_idx, milestone_inx].to_s ).to include 'milestone 1'
      end

      it 'should export a model and  assocs in json to .xls file' do
        create( :project_with_user )
        create( :project_with_milestones )

        expected = result_file('project_and_has_many_json_export.xls')

        gen = ExcelExporter.new(expected)

        items = Project.all

        gen.export_with_associations(Project, items, json: true)

        expect(File.exist?(expected)).to eq true

        excel = Excel.new
        excel.open(expected)

        expect(excel.num_rows).to eq Project.count + 1

        milestone_inx = excel.row(0).index 'milestones'

        last_idx = Project.count
        expect( excel[last_idx, milestone_inx].to_s ).to include '['
        expect( excel[last_idx, milestone_inx].to_s ).to match /name\":\"milestone/
      end
    end

  end
end
