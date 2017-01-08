# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT
#
#
require_relative '../../spec_helper'

module DataShift

  describe 'Excel Loader - Using Mappings' do
    include_context 'ClearAllCatalogues'

    before(:each) do
      DataShift::Transformation::Factory.reset
    end

    let(:loader) { ExcelLoader.new }

    let(:expected) { ifixture_file('SimpleProjects.xls') }

    context 'configured load operations' do

      before(:each) do
        create_list(:category, 5)
      end

      it 'should bind headers to class methods based on mapping' do
        loader.run(expected, Project)

        expect(loader.binder).to be

        binding = loader.binder.bindings[1]

        expect(binding.valid?).to eq true
        expect(binding.index).to eq 1
        expect(binding.source).to eq 'Value as Text'
        expect(binding.operator).to eq 'value_as_text'

        expect(Project.new.respond_to?(binding.operator)).to eq true
      end
    end

  end

end
