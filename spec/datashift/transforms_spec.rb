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

    context 'Column removals' do
      it 'should process options to remove unwant5ed columns' do
        headers = [:a, :b, :c, :d, :e, :f]

        DataShift::Exporters::Configuration.configure do |config|
          config.remove = [:b, :f]
        end

        DataShift::Transformer::Remove.unwanted_columns(headers )

        expect(headers).to_not include [:b, :f]
      end

      it 'should process options to remove unwant5ed columns' do
        headers = [:a, :id, :c, :d, :e, :created_on, :f, :updated_on]

        DataShift::Exporters::Configuration.configure do |config|
          config.remove_rails = true
        end

        DataShift::Transformer::Remove.unwanted_columns(headers )

        expect(headers).to_not include [:id, :created_on, :updated_on]
      end

    end

    context 'Configuration of Transformations' do
      it 'should provide facility to set default values via YAML configuration' do
        pending 'refactoring this out of loader'

        sometransformer.configure_from( ifixture_file('ProjectsDefaults.yml') )
      end

      it 'should provide facility to over ride values via YAML configuration' do
        pending 'refactoring this out of loader'

        sometransformer.configure_from( ifixture_file('ProjectsDefaults.yml') )
      end
    end
  end

end
