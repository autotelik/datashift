# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::   Specs for MethodBinding aspect of Active Record Loader
#             MethodBinding holds details of a method call on an AR object
#             linked to the incoming column header/index
#
require File.join(File.dirname(__FILE__), '/../spec_helper')

module DataShift

  describe 'Method Binding' do
    include_context 'ClearThenManageProject'

    let( :model_method) { project_collection.search('value_as_string') }

    it 'should bind details of inbound header to domain model' do
      binding = MethodBinding.new('value_as_string', 1, model_method)
      expect(binding).to be
    end

    context ('Bound to Header') do
      let(:binding) { MethodBinding.new('value_as_string', 1, model_method) }

      let(:valid_column_on_project) { 'value_as_string' }

      it 'should provide access to inbound column (header)' do
        expect(binding.inbound_column).to be_a InboundData::Column
      end

      it 'should provide access to domain model method' do
        expect(binding.model_method).to eq model_method
      end

      it 'should enable an index to be set for index style processors' do
        binding = MethodBinding.new(valid_column_on_project, 2, model_method)
        expect(binding.inbound_column.index).to eq 2

        binding = MethodBinding.new(valid_column_on_project, 99999, model_method)
        expect(binding.inbound_column.index).to eq 99999
      end

      it 'should be valid when both name and model method provided' do
        binding = MethodBinding.new(valid_column_on_project, 2, model_method)
        expect(binding.valid?).to eq true
      end

      it 'should be invalid when either name or model method nil' do
        binding = MethodBinding.new(nil, 3, model_method)
        expect(binding.valid?).to eq false

        binding = MethodBinding.new(valid_column_on_project, 3, nil)
        expect(binding.valid?).to eq false
      end
    end
  end

end
