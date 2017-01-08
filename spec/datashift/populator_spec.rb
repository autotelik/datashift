# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
#
require_relative '../spec_helper'

module DataShift

  describe 'Populator' do
    include_context 'ClearThenManageProject'

    it 'should be able to create a new populator' do
      expect(DataShift::Populator.new).to be
    end

    it 'should process a DSL string into a real hash' do
      str1 = "{:name => 'the_fox' }"

      x = DataShift::Populator.string_to_hash( str1 )

      expect(x).to be_a Hash
      expect(x.size).to eq 1

      str2 = "{:name => 'the_fox', 'occupation' => 'fantastic', :food => 'duck soup' }"

      x = DataShift::Populator.string_to_hash( str2 )

      expect(x.size).to eq 3
      expect(x).to eq('name' => 'the_fox', 'occupation' => 'fantastic', 'food' => 'duck soup')
    end

    it 'should process simplified syntax string into a real hash' do
      str3 = "{cost_price: '13.45', price: 23,  sale_price: 4.23 }"

      x = DataShift::Populator.string_to_hash( str3 )

      expect(x.keys).to include 'price'
      expect(x['cost_price']).to eq '13.45'
      expect(x['price']).to eq 23
      expect(x['sale_price']).to eq 4.23
    end

    it 'should process mixed hash syntax string into a real hash' do
      str = "{:cost_price => '13.45', price: 23,  :sale_price => 4.23 }"

      x = DataShift::Populator.string_to_hash( str )

      expect(x.size).to eq 3
      expect(x.keys).to include 'cost_price'
      expect(x.keys).to include 'price'
      expect(x['cost_price']).to eq '13.45'
      expect(x['price']).to eq 23
      expect(x['sale_price']).to eq 4.23
    end

    context 'prepare data' do
      let(:model_method)    { project_collection.search('value_as_string') }

      let(:method_binding)  { MethodBinding.new('value_as_string', 1, model_method) }

      let(:populator)       { DataShift::Populator.new }

      let(:data)            { 'some text for the string' }

      it 'should prepare inbound string data for a method binding' do
        value, attributes = populator.prepare_data(method_binding, data)

        expect(value).to eq data
        expect(attributes).to be_a Hash
        expect(attributes.empty?).to eq true
      end

      it 'should prepare inbound array data for a method binding' do
        list = create_list(:milestone, 4)

        method_binding =  MethodBinding.new('milestones', 1, project_collection.search('milestones') )

        value, attributes = populator.prepare_data(method_binding, list)

        expect(value).to eq list
        expect(attributes).to be_a Hash
        expect(attributes.empty?).to eq true
      end

      it 'should prepare inbound active relation a method binding' do
        create_list(:loader_release, 5)

        list = LoaderRelease.all

        method_binding =  MethodBinding.new('milestones', 1, project_collection.search('milestones') )

        value, attributes = populator.prepare_data(method_binding, list)

        expect(value).to be_a Array
        expect(value.size).to eq list.size

        expect(attributes).to be_a Hash
        expect(attributes.empty?).to eq true
      end

      it 'should process a string value with attributes' do
        data = 'Get up Lazy fox {:name => \'the_fox\', food: chickens }'

        value, attributes = populator.prepare_data(method_binding, data)

        expect(value).to eq 'Get up Lazy fox '

        expect(attributes).to be_a Hash
        expect(attributes.size).to eq 2
        expect(attributes.keys).to include 'name'
        expect(attributes['name']).to eq 'the_fox'
      end
    end
  end

end # module
