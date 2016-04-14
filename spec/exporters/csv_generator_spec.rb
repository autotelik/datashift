# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/../spec_helper'

module  DataShift

  describe 'CSV Generator' do

    before(:all) do
      results_clear( '*_template.csv' )
    end

    before(:each) do
      DataShift::Exporters::Configuration.reset
    end

    include_context 'ClearThenManageProject'

    let(:generator) { CsvGenerator.new }

    it 'should be able to create a new csv generator' do
      expect(generator).to_not be_nil
    end

    it 'should generate template .csv file from model' do
      expected = result_file('project_template.csv')

      generator.generate(expected, Project)

      expect(File.exist?(expected)).to eq true

      csv = CSV.read(expected)

      headers = csv[0]

      %w(title value_as_string value_as_text value_as_boolean value_as_datetime value_as_integer value_as_double).each do |check|
        expect(headers.include?(check)).to eq  true
      end
    end

    # has_one  :owner
    # has_many :milestones
    # has_many :loader_releases
    # has_many :versions, :through => :loader_releases
    # has_and_belongs_to_many :categories

    it 'should include all associations in template .csv file from model' do
      expected = result_file('project_plus_assoc_template.csv')

      generator.generate_with_associations(expected, Project)

      expect( File.exist?(expected)).to eq true

      csv = CSV.read(expected)

      headers = csv[0]

      %w(owner milestones loader_releases versions categories).each do |check|
        expect(headers.include?(check)).to eq  true
      end
    end

    it 'should enable us to exclude associations by type in template .csv file' do
      expected = result_file('project_plus_some_assoc_template.csv')

      DataShift::Exporters::Configuration.configure do |config|
        config.exclude = [:has_many]
      end

      generator.generate_with_associations(expected, Project)

      expect(File.exist?(expected)).to eq true # , "Failed to find expected result file #{expected}"

      csv = CSV.read(expected)

      headers = csv[0]

      expect(headers.include?('title')).to eq true
      expect(headers.include?('owner')).to eq true

      %w(milestones loader_releases versions categories).each do |check|
        expect(headers).to_not include check
      end
    end

    it 'should enable us to exclude certain associations', fail: true do
      expected = result_file('project_plus_some_assoc_template.csv')

      DataShift::Exporters::Configuration.configure do |config|
        config.remove = [:milestones, :versions]
      end

      generator.generate_with_associations(expected, Project)

      expect(File.exist?(expected)).to eq true # , "Failed to find expected result file #{expected}"

      csv = CSV.read(expected)

      headers = csv[0]

      %w(title loader_releases owner categories).each do |check|
        expect(headers).to include check
      end

      %w(milestones versions).each do |check|
        expect(headers).to_not include check
      end
    end

    it 'should remove standard rails fields from template .csv file' do
      expected = result_file('project_plus_some_assoc_template.csv')

      DataShift::Exporters::Configuration.configure do |config|
        config.remove_rails = true
      end

      generator.generate_with_associations(expected, Project)

      expect(File.exist?(expected)).to eq true # , "Failed to find expected result file #{expected}"

      csv = CSV.read(expected)

      headers = csv[0]

      %w(id updated_at created_at).each do |check|
        expect(headers).to_not include check
      end
    end
  end

end
