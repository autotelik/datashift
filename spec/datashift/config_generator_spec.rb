# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT
#
#
require File.join(File.dirname(__FILE__), '/../spec_helper')

module DataShift

  describe  DataShift::ConfigGenerator do
    include_context 'ClearAllCatalogues'

    before(:each) do
      results_clear
    end

    let(:config_generator) { DataShift::ConfigGenerator.new }

    let(:expected_config_file) { result_file('mapping_service_project.yaml') }

    let(:generate_config_file) {  config_generator.write_import(expected_config_file, Project) }

    context 'erb generation' do

      context 'basic templates without a class' do
        it 'should generate an standard ERB template containing default mappings & config' do
          result = config_generator.create_import_erb Project

          expect(result).to be_a String
          expect(result).to match '#src_column_heading_0:'
        end

        it 'should have a consistent starting title' do
          result = config_generator.create_import_erb Project

          expect(result).to include 'Project'
        end
      end

      context 'real mappings' do
        let(:map_file) { result_file('project_mapper.yaml') }

        it 'should generate a populated mapping doc for a class' do
          generate_config_file

          expect(File.exist?(expected_config_file)).to be true
          expect( File.read(expected_config_file) ).to include 'Project:'
        end

        it 'should be able to extract headers from_excel', fail: true do
          config_generator.generate_from_excel(ifixture_file('SimpleProjects.xls') )

          expect(config_generator.headers.empty?).to eq false
          expect(config_generator.headers.class).to eq Headers
        end

        it 'should be able to extract headers from_excel' do
          config_generator.generate_from_excel(ifixture_file('SimpleProjects.xls') )

          # bit flakey need to manually st expected spreadsheet values
          # value_as_string,	Value as Text,	value as datetime,	value_as_boolean,	value_as_double

          expect(config_generator.headers.size).to eq 5
          expect(config_generator.headers[0]).to eq 'value_as_string'
          expect(config_generator.headers[4]).to eq 'value_as_double'
        end

        it 'should be able to generate a mapping from_excel' do
          expect(File.exist?(map_file)).to be false

          config_generator.generate_from_excel(ifixture_file('SimpleProjects.xls'), file: map_file )

          expect(File.exist?(map_file)).to be true
        end
      end
    end

    context 'Import' do

      let(:expected_columns) { Project.new.serializable_hash.keys }

      it 'should be able to write out a basic configuration document for a class' do
        expect(File.exist?(expected_config_file)).to_not be true

        expect { generate_config_file }.to_not raise_error

        expect(File.exist?(expected_config_file)).to be true
      end

      it 'a basic mapping document should contain at least attributes of a class' do
        generate_config_file

        File.foreach(expected_config_file)
        expect( $.).to be > expected_columns.size
      end


      it 'a basic mapping document can be configures to contain associations as well' do

        DataShift::Exporters::Configuration.configure do |config|
          config.with = [:all]
        end

        generate_config_file

        expect(File.exist?(expected_config_file)).to be true

        File.foreach(expected_config_file)
        expect( $.).to be > expected_columns.size
      end

    end

    # TODO: split into two - with and without associations

    context 'Reading' do

      let(:mapping_service) { FlowProducerFactory.new(Project) }

      before(:each) do
        generate_config_file

        expect(File.exist?(expected_config_file)).to be true

        mapping_service.read(expected_config_file)
      end

      it 'should be able to read a mapping' do
        expect(mapping_service.map_file_name).to eq expected_config_file

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

        expect(project_mappings.key?('column_mappings')).to eq true
        expect(project_mappings.key?('defaults')).to eq true
        expect(project_mappings.key?('substitutions')).to eq true
      end
    end

  end
end # module
