# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Specs around Transforming inbound data
#
require File.join(File.dirname(__FILE__), '/../../spec_helper')

module  DataShift

  describe Transformation do
    include_context 'ClearThenManageProject'

    context 'basics' do

      it 'should create standard method formats for all transformations' do

        name = DataShift::Transformation::Factory::TRANSFORMERS_HASH_INSTANCE_NAMES.first

        expect(DataShift::Transformation.factory).to respond_to "#{name}s_for"

        expect(DataShift::Transformation.factory).to respond_to "defaults_for"
        expect(DataShift::Transformation.factory).to respond_to "set_default"
        expect(DataShift::Transformation.factory).to respond_to "set_default_on"
        expect(DataShift::Transformation.factory).to respond_to "default?"
        expect(DataShift::Transformation.factory).to respond_to "default"
        expect(DataShift::Transformation.factory).to respond_to "get_default_on"
      end


      it 'should enable settings to be cleared' do

        #  [:default, :override, :substitution, :prefix, :postfix]

        DataShift::Transformation.factory do |factory|
          factory.set_default_on(Project, "name", 'default name')
          factory.set_override_on(Project, "name", 'override name')
          factory.set_prefix_on(Project, "name", 'prefix name')
          factory.set_postfix_on(Project, "name", 'postfix name')

          factory.set_substitution_on(Project, "name", 'if its blah', 'substitution name')
        end

        expect(DataShift::Transformation.factory.get_default_on(Project, "name")).to eq 'default name'
        expect(DataShift::Transformation.factory.get_override_on(Project, "name")).to eq 'override name'
        expect(DataShift::Transformation.factory.get_prefix_on(Project, "name")).to eq 'prefix name'
        expect(DataShift::Transformation.factory.get_postfix_on(Project, "name")).to eq 'postfix name'
        expect(DataShift::Transformation.factory.get_substitution_on(Project, "name")).to be_a Struct::Substitution

        DataShift::Transformation.factory.clear

        expect(DataShift::Transformation.factory.get_default_on(Project, "name")).to be_nil
        expect(DataShift::Transformation.factory.get_override_on(Project, "blah")).to be_nil
        expect(DataShift::Transformation.factory.get_prefix_on(Project, "blah")).to be_nil
        expect(DataShift::Transformation.factory.get_postfix_on(Project, "blah")).to be_nil
        expect(DataShift::Transformation.factory.get_substitution_on(Project, "blah")).to be_nil
      end
    end

    context 'over-rides' do
      let(:model_method)    { project_collection.search('value_as_string') }

      let(:method_binding)  { MethodBinding.new('value_as_string', 1, model_method) }

      let(:populator)       { DataShift::Populator.new }

      let(:data)            { 'some text for the string' }

      before(:each) do
        DataShift::Transformation.factory.clear

        DataShift::Exporters::Configuration.reset
      end

      it 'over-ride should always over-ride value regardless of real value' do
        DataShift::Transformation.factory do |factory|
          factory.set_override(method_binding, 'override text')
        end

        value, _attributes = populator.prepare_data(method_binding, data)

        expect(value).to eq 'override text'
      end

      context 'DefaultValues for Columns' do
        it 'should use default value when nil' do
          DataShift::Transformation.factory do |factory|
            factory.set_default(method_binding, 'default text')
          end

          value, _attributes = populator.prepare_data(method_binding, nil)
          expect(value).to eq 'default text'
        end

        it 'should use default value when empty string' do
          DataShift::Transformation.factory do |factory|
            factory.set_default(method_binding, 'default text')
          end

          value, _attributes = populator.prepare_data(method_binding, '')
          expect(value).to eq 'default text'
        end
      end

      it 'should use substitution when relevant' do
        DataShift::Transformation.factory do |factory|
          factory.set_substitution(method_binding, 'text', ' replaced with me')
        end

        value, _attributes = populator.prepare_data(method_binding, data)
        expect(value).to eq 'some  replaced with me for the string'
      end

      it 'should add a prefix' do
        DataShift::Transformation.factory do |factory|
          factory.set_prefix(method_binding, 'added me before')
        end

        value, _attributes = populator.prepare_data(method_binding, data)
        expect(value).to eq 'added me before' + data
      end

      it 'should add a postfix' do
        DataShift::Transformation.factory do |factory|
          factory.set_postfix(method_binding, 'added me after')
        end

        value, _attributes = populator.prepare_data(method_binding, data)
        expect(value).to eq data + 'added me after'
      end
    end

    let(:config_file) {ifixture_file('config/ProjectConfiguration.yml') }

    context 'Configuration of Transformations' do

      before(:each) do
        DataShift::Transformation.factory.clear
        DataShift::Transformation.factory.configure_from(Project, config_file )
      end

      it 'should provide facility to set default values via YAML configuration' do
        defaults =  DataShift::Transformation.factory.defaults_for(Project)
        expect(defaults).to be_a Hash
        expect(defaults.size).to eq 3
      end

      it 'should provide facility to set override values via YAML configuration' do
        override =  DataShift::Transformation.factory.overrides_for(Project )
        expect(override).to be_a Hash
        expect(override.has_key?('value_as_integer')).to eq true
        expect(override.size).to eq 2
      end

      it 'should provide facility to substitute values via YAML configuration' do
        substitutes =  DataShift::Transformation.factory.substitutions_for(Project )
        expect(substitutes).to be_a Hash
        expect(substitutes.has_key?('value_as_text')).to eq true

        sub = substitutes['value_as_text']

        expect(sub).to be_a Struct::Substitution
        expect(sub.pattern).to eq "change me"
        expect(sub.replacement).to eq "i only gone and got myself changed by datashift"

        expect(substitutes.size).to eq 1
      end

      it 'should provide facility to set prefixes via YAML configuration' do
        prefixes =  DataShift::Transformation.factory.prefixes_for(Project )
        expect(prefixes).to be_a Hash
        expect(prefixes.has_key?('value_as_string')).to eq true
        expect(prefixes.size).to eq 1
      end

      it 'should provide facility to set postfixes via YAML configuration' do
        postfixes =  DataShift::Transformation.factory.postfixes_for(Project )
        expect(postfixes).to be_a Hash
        expect(postfixes.has_key?('value_as_integer')).to eq false
        expect(postfixes.has_key?('value_as_string')).to eq true
        expect(postfixes.has_key?('value_as_text')).to eq true
        expect(postfixes.size).to eq 2
      end

      after(:all) do
        DataShift::Transformation.factory.clear
      end

    end
  end

end
