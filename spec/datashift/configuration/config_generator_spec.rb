# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT
#
require_relative '../../spec_helper'

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
          result = config_generator.create_import_config Project

          expect(result).to be_a String
          expect(result).to include 'Project:'
          expect(result).to include 'nodes:'
        end

        it 'should have a consistent starting title' do
          result = config_generator.create_import_config Project

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

        it 'should be able to extract headers from_excel' do
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


      it 'a basic mapping document can be configures to contain associations as well', duff: true do

        DataShift::Exporters::Configuration.configure do |config|
          config.with = [:all]
        end

        generate_config_file

        expect(File.exist?(expected_config_file)).to be true

        File.foreach(expected_config_file)

        puts File.read expected_config_file

        expect( $.).to be > expected_columns.size
      end


      it 'should enable us to exclude certain headers', duff: true do

        DataShift::Configuration.call.remove_columns = [:milestones, :versions]
        end

    end

    # TODO: split into two - with and without associations

    context 'Reading' do

      let(:data_flow_schema) { DataFlowSchema.new }

      let(:expected_config_file) { result_file('mapping_service_project.yaml') }

      let(:options) {
        {
          defaults:  {'value_as_string': 'some default text', 'value_as_double': 45.467 },
          overrides: {'value_as_double': 45.467 },
          postfixes: {'value_as_text': 'postfix value_as_text' },
          substitutions:  { 'owner' => ['sub this text', 'for some other text'] }
          # prefixs
        }
      }

      let(:generate_config_file) { config_generator.write_import(expected_config_file, Project, options) }

      before(:each) do

        config = generate_config_file

        expect(config).to be_a String
        expect(config).to_not be_empty

        expect(File.exist?(expected_config_file)).to be true

        data_flow_schema.prepare_from_file(expected_config_file)
      end

      it 'should store the raw mapping data' do
        expect(data_flow_schema.raw_data).to_not be_empty
        expect(data_flow_schema.yaml_data).to_not be_empty
      end

      it 'should read in the nodes for this data schema' do
        expect(data_flow_schema.nodes).to be_a NodeCollection
        expect(data_flow_schema.nodes).to_not be_empty

        node = data_flow_schema.nodes[0]
        expect(node).to be_a NodeContext
      end

      it 'should provide access to details of the schema' do
        expect(data_flow_schema.nodes.doc_context).to be_a DocContext
        expect(data_flow_schema.nodes.doc_context.klass).to eq Project

      end

      it 'should have configured the Transformer', duff: true do

        postfixes =  DataShift::Transformation.factory.postfixes_for(Project)

        expect(postfixes).to be_a Hash
        expect(postfixes.has_key?('value_as_integer')).to eq false
        expect(postfixes.has_key?('value_as_text')).to eq true
        expect(postfixes.size).to eq 1

        expect(DataShift::Transformation.factory.defaults_for(Project).size).to eq 2
        expect(DataShift::Transformation.factory.overrides_for(Project).size).to eq 1
        expect(DataShift::Transformation.factory.substitutions_for(Project).size).to eq 1
        expect(DataShift::Transformation.factory.prefixes_for(Project).size).to eq 0

        expect(DataShift::Transformation.factory.get_postfix_on(Project, :value_as_text)).to eq 'postfix value_as_text'
      end
    end

  end
end # module
