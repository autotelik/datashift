# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Feb 2015
# License::   MIT
#
# Details::   Specs for Mapping aspects
#             Provides automatic mapping between different system's column headings
#
require File.join(File.dirname(__FILE__), 'spec_helper')


module DataShift

  describe 'Mapping Services' do

    include_context "ClearAllCatalogues"

    before(:each) do
      results_clear
    end

    context 'generation' do

      it "should be able to create a mapping service for a class" do
        mapping_services = DataShift::MappingServices.new(Project)

        expect(mapping_services).to be
      end

    end

    let(:mapper) { DataShift::MappingGenerator.new }

    let(:mapping_service) {  DataShift::MappingServices.new(Project) }

    context 'reading' do

      let(:mfile) { result_file("mapping_service_project.yaml") }

      before(:each) do
        mapper.generate(Project, {:file => mfile} )

        expect(File.exists?(mfile)).to be true

        mapping_service.read(mfile)
      end

=begin
      Project:
          title: #dest_column_heading_0
          value_as_string: #dest_column_heading_1
          value_as_text: #dest_column_heading_2
          value_as_boolean: #dest_column_heading_3
          value_as_datetime: #dest_column_heading_4
          value_as_integer: #dest_column_heading_5
          value_as_double: #dest_column_heading_6
          user_id: #dest_column_heading_7
          user: #dest_column_heading_8
          owner: #dest_column_heading_9
          milestones: #dest_column_heading_10
          loader_releases: #dest_column_heading_11
          versions: #dest_column_heading_12
          categories: #dest_column_heading_13
=end

      it "should be able to read a mapping" do

        expect(mapping_service.map_file_name).to eq mfile

        expect(mapping_service.raw_data).to_not be_empty
        expect(mapping_service.yaml_data).to_not be_empty

        expect(mapping_service.mappings).to be_a OpenStruct
      end

      it "should provide access to the top level mapping" do
        expect(mapping_service.mappings.Project).to be_a Hash
        expect(mapping_service.mappings['Project']).to be_a Hash
      end


      it "should provide access to the collection of mappings under top level" do

        project_mappings = mapping_service.mappings['Project']

        expect(project_mappings.has_key?('title')).to eq true
        expect(project_mappings.has_key?('value_as_integer')).to eq true
        expect(project_mappings.has_key?('versions')).to eq true
      end

    end

    context 'using' do

      let(:mfile) { ifixture_file("project_mapping.yaml") }

      before(:each) do
        expect(File.exists?(mfile)).to be true

        mapping_service.read(mfile)

        @project_mappings = mapping_service.mappings['Project']
      end

      it "should be able to reach destination for a  mapping", :fail => true do

        expect(@project_mappings['title']).to eq 'TheTitle'
        expect(@project_mappings['value_as_integer']).to eq 'A Number'
        expect(@project_mappings['versions']).to eq 'Indexes'

      end

    end

  end
end # module