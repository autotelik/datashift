# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require_relative '../../spec_helper'

require 'erb'
require 'excel_generator'

module DataShift

  describe 'Excel Generator' do
    include_context 'ClearThenManageProject'

    before(:all) do
      results_clear( '*_template.xls' )
    end

    before(:each) do
      DataShift::Exporters::Configuration.reset
    end

    let(:generator) { ExcelGenerator.new }

    it 'should be able to create a new excel generator' do
      expect(generator).to_not be_nil
    end

    it 'should generate template .xls file from model' do
      expected = result_file('gen_project_template.xls')

      generator.generate(expected, Project)

      expect(File.exist?(expected)).to eq true

      puts "Can manually check file @ #{expected}"

      excel = Excel.new
      excel.open(expected)

      expect(excel.worksheets.size).to eq 1

      expect(excel.worksheet(0).name).to eq 'Project'

      headers = excel.worksheets[0].row(0)

      expect(headers).to include(*Project.columns.collect(&:name))

    end

    # has_one  :owner
    # has_many :milestones
    # has_many :loader_releases
    # has_many :versions, :through => :loader_releases
    # has_and_belongs_to_many :categories

    it 'should include all associations in template .xls file from model', duff: true do
      expected = result_file('gen_project_plus_assoc_template.xls')

      generator.generate_with_associations(expected, Project)

      expect( File.exist?(expected)).to eq true

      excel = Excel.new
      excel.open(expected)

      expect(excel.worksheets.size).to eq 1

      expect(excel.worksheet(0).name).to eq 'Project'

      headers = excel.worksheets[0].row(0).to_a

      expect(headers).to include(*Project.columns.collect(&:name))

      %w(owner milestones loader_releases versions categories).each do |check|
        expect(headers.include?(check)).to eq true
      end
    end

    it 'should enable us to exclude associations by type in template .xls file' do
      expected = result_file('gen_project_plus_some_assoc_template.xls')

      DataShift::Configuration.configure do |config|
        config.exclude = :has_many
      end

      generator.generate_with_associations(expected, Project)

      expect(File.exist?(expected)).to eq true # , "Failed to find expected result file #{expected}"

      excel = Excel.new
      excel.open(expected)

      expect(excel.worksheets.size).to eq 1

      expect( excel.worksheet(0).name).to eq 'Project'

      headers = excel.worksheets[0].row(0)


      expect(headers).to include(*Project.columns.collect(&:name))

      expect(headers.include?('title')).to eq  true
      expect(headers.include?('owner')).to eq  true

      %w(milestones loader_releases versions categories).each do |check|
        expect(headers).to_not include check
      end
    end

    it 'should enable us to exclude certain associations in template .xls file ', duff: true do
      expected = result_file('gen_project_plus_some_assoc_template.xls')

      DataShift::Configuration.call.remove_columns = [:milestones, :versions]

      generator.generate_with_associations(expected, Project)

      expect(File.exist?(expected)).to eq true # , "Failed to find expected result file #{expected}"

      excel = Excel.new
      excel.open(expected)

      expect(excel.worksheets.size).to eq 1

      expect(excel.worksheet(0).name).to eq 'Project'

      headers = excel.worksheets[0].row(0)

      %w(title loader_releases owner categories).each do |check|
        expect(headers).to include check
      end

      %w(milestones versions).each do |check|
        expect(headers).to_not include check
      end
    end

    it 'should enable us to remove standard rails feilds from template .xls file ' do
      expected = result_file('gen_project_plus_some_assoc_template.xls')

      DataShift::Configuration.call.remove_rails = true

      generator.generate_with_associations(expected, Project)

      expect(File.exist?(expected)).to eq true # , "Failed to find expected result file #{expected}"

      excel = Excel.new
      excel.open(expected)

      expect(excel.worksheets.size).to eq 1

      expect(excel.worksheet(0).name).to eq 'Project'

      headers = excel.worksheets[0].row(0)

      %w(id updated_at created_at).each do |check|
        expect(headers).to_not include check
      end
    end

    it 'should enable us to autosize columns in the .xls file' do
      expected = result_file('gen_project_autosized_template.xls')

      pending "Auto sizing of Excel columns"

      DataShift::Exporters::Configuration.configure do |config|
        config.autosize = true
      end

      generator.generate_with_associations(expected, Project)

      expect( File.exist?(expected)).to eq true

      excel = Excel.new
      excel.open(expected)
    end
  end

end
