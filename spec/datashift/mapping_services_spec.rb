# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Specs for Mapping aspects
#             Provides automatic mapping between different system's column headings
#
require File.join(File.dirname(__FILE__), '/../spec_helper')

module DataShift

  describe 'Mapping Services' do
    include_context 'ClearAllCatalogues'

    before(:each) do
      results_clear
    end

    it 'should be able to create a mapping service for a class' do
      mapping_services = DataShift::MappingServices.new(Project)

      expect(mapping_services).to be
    end

    context 'Generation' do

      let(:expected_columns) { Project.new.serializable_hash.keys }

      let(:mapper) { DataShift::MappingGenerator.new }

      let(:expected_map_file) { result_file('mapping_service_project.yaml') }

      it 'should be able to create a mapping generator' do
        expect(mapper).to be
      end

      it 'should be able to write out a basic mapping document for a class' do
        expect(File.exist?(expected_map_file)).to_not be true

        expect { mapper.generate(Project, file: expected_map_file, with: :all) }.to_not raise_error

        expect(File.exist?(expected_map_file)).to be true
      end

      it 'a basic mapping document should contain at least attributes of a class' do
        mapper.generate(Project, file: expected_map_file)

        File.foreach(expected_map_file)
        expect( $.).to be > expected_columns.size
      end


      it 'a basic mapping document can be configures to contain associations as well' do

        DataShift::Exporters::Configuration.configure do |config|
          config.with = [:all]
        end

        mapper.generate(Project, file: expected_map_file)

        expect(File.exist?(expected_map_file)).to be true

        File.foreach(expected_map_file)
        count = $.
        expect( $.).to be > expected_columns.size
      end

    end


    # TODO: split into two - with and without associations

    context 'Reading' do

      let(:expected_map_file) { result_file('mapping_service_project.yaml') }

      let(:mapper) { DataShift::MappingGenerator.new }

      let(:mapping_service) { DataShift::MappingServices.new(Project) }

      before(:each) do
        mapper.generate(Project, file: expected_map_file )

        expect(File.exist?(expected_map_file)).to be true

        mapping_service.read(expected_map_file)
      end

      #       Project:
      #           title: #dest_column_heading_0
      #           value_as_string: #dest_column_heading_1
      #           value_as_text: #dest_column_heading_2
      #           value_as_boolean: #dest_column_heading_3
      #           value_as_datetime: #dest_column_heading_4
      #           value_as_integer: #dest_column_heading_5
      #           value_as_double: #dest_column_heading_6
      #           user_id: #dest_column_heading_7
      #
      #           user: #dest_column_heading_8
      #           owner: #dest_column_heading_9
      #           milestones: #dest_column_heading_10
      #           loader_releases: #dest_column_heading_11
      #           versions: #dest_column_heading_12
      #           categories: #dest_column_heading_13

      it 'should be able to read a mapping' do
        expect(mapping_service.map_file_name).to eq expected_map_file

        expect(mapping_service.raw_data).to_not be_empty
        expect(mapping_service.yaml_data).to_not be_empty

        expect(mapping_service.mappings).to be_a OpenStruct
      end

      it 'should provide access to the top level mapping' do
        expect(mapping_service.mappings.Project).to be_a Hash
        expect(mapping_service.mappings['Project']).to be_a Hash
      end

      it 'should provide access to the collection of mappings under top level' do
        project_mappings = mapping_service.mappings['Project']

        expect(project_mappings.key?('title')).to eq true
        expect(project_mappings.key?('value_as_integer')).to eq true
        expect(project_mappings.key?('versions')).to eq true
      end
    end

    context 'Using' do
      let(:expected_map_file) { ifixture_file('project_mapping.yaml') }

      let(:mapping_service) { DataShift::MappingServices.new(Project) }

      before(:each) do
        expect(File.exist?(expected_map_file)).to be true

        mapping_service.read(expected_map_file)

        @project_mappings = mapping_service.mappings['Project']
      end

      it 'should be able to reach destination for a  mapping' do
        expect(@project_mappings['title']).to eq 'TheTitle'
        expect(@project_mappings['value_as_integer']).to eq 'A Number'
        expect(@project_mappings['versions']).to eq 'Indexes'
      end
    end
  end
end # module
