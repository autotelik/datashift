# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Specs around Transforming inbound data
#
require File.dirname(__FILE__) + '/../spec_helper'

module  DataShift

  describe 'Transforms' do
    include_context 'ClearThenManageProject'

    context 'over-rides' do
      let(:model_method)    { project_collection.search('value_as_string') }

      let(:method_binding)  { MethodBinding.new('value_as_string', 1, model_method) }

      let(:populator)       { DataShift::Populator.new }

      let(:data)            { 'some text for the string' }

      before(:each) do
        DataShift::Transformer.factory.clear

        DataShift::Exporters::Configuration.reset
      end

      it 'over-ride should always over-ride value regardless of real value' do
        DataShift::Transformer.factory do |factory|
          factory.set_override(method_binding, 'override text')
        end

        value, _attributes = populator.prepare_data(method_binding, data)

        expect(value).to eq 'override text'
      end

      context 'DefaultValues for Columns' do
        it 'should use default value when nil' do
          DataShift::Transformer.factory do |factory|
            factory.set_default(method_binding, 'default text')
          end

          value, _attributes = populator.prepare_data(method_binding, nil)
          expect(value).to eq 'default text'
        end

        it 'should use default value when empty string' do
          DataShift::Transformer.factory do |factory|
            factory.set_default(method_binding, 'default text')
          end

          value, _attributes = populator.prepare_data(method_binding, '')
          expect(value).to eq 'default text'
        end
      end

      it 'should use substitution when relevant' do
        DataShift::Transformer.factory do |factory|
          factory.set_substitution(method_binding, 'text', ' replaced with me')
        end

        value, _attributes = populator.prepare_data(method_binding, data)
        expect(value).to eq 'some  replaced with me for the string'
      end

      it 'should add a prefix' do
        DataShift::Transformer.factory do |factory|
          factory.set_prefix(method_binding, 'added me before')
        end

        value, _attributes = populator.prepare_data(method_binding, data)
        expect(value).to eq 'added me before' + data
      end

      it 'should add a postfix' do
        DataShift::Transformer.factory do |factory|
          factory.set_postfix(method_binding, 'added me after')
        end

        value, _attributes = populator.prepare_data(method_binding, data)
        expect(value).to eq data + 'added me after'
      end
    end

    let(:config_file) {ifixture_file('ProjectConfiguration.yml') }

    context 'Configuration of Transformations' do
      it 'should provide facility to set default values via YAML configuration', duff: true do
        DataShift::Transformer.factory.configure_from( Project, config_file )

        defaults =  DataShift::Transformer.factory.defaults_for( Project )
        expect(defaults).to be_a Hash
        expect(defaults.size).to eq 3
      end

      it 'should provide facility to set override values via YAML configuration', duff: true do
        DataShift::Transformer.factory.configure_from( Project, config_file )

        override =  DataShift::Transformer.factory.overrides_for( Project )
        expect(override).to be_a Hash
        expect(override.has_key?('value_as_integer')).to eq true
        expect(override.size).to eq 2
      end

      it 'should provide facility to set prefixes via YAML configuration' do
        DataShift::Transformer.factory.configure_from( Project, config_file )

        prefixes =  DataShift::Transformer.factory.prefixes_for( Project )
        expect(prefixes).to be_a Hash
        expect(prefixes.has_key?('value_as_string')).to eq true
        expect(prefixes.size).to eq 1
      end

      it 'should provide facility to set postfixes via YAML configuration' do
        DataShift::Transformer.factory.configure_from( Project, config_file )

        postfixes =  DataShift::Transformer.factory.postfixes_for( Project )
        expect(postfixes).to be_a Hash
        expect(postfixes.has_key?('value_as_string')).to eq true
        expect(postfixes.size).to eq 1
      end


    end
  end

end
