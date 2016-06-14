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
      mapping_services = DataShift::Header.new(Project)

      expect(mapping_services).to be
    end


    # TODO: split into two - with and without associations

    context 'Reading' do

      let(:expected_map_file) { result_file('mapping_service_project.yaml') }

      let(:config_generator) { DataShift::ConfigGenerator.new }

      let(:mapping_service) { DataShift::Header.new(Project) }

      before(:each) do
        config_generator.write_import(expected_map_file, Project)

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

    end

    context 'Using' do

      # TODO - generated dynamically from latest templates ??
      let(:expected_map_file) { ifixture_file('project_mapping.yaml') }

      let(:mapping_service) { DataShift::Header.new(Project) }

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
