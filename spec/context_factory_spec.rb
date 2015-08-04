# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
require File.dirname(__FILE__) + '/spec_helper'

module DataShift

  describe 'Context Factory' do
    include_context 'ClearThenManageProject'

    before(:each) do
      ContextFactory.clear_populators
    end

    let(:model_method)  { project_collection.search('value_as_string') }

    let(:method_binding) { MethodBinding.new('column_for_value_as_string', 0, model_method) }

    context 'configuring' do
      it 'can be configured to provide a specific Populator per operator' do
        class AnotherPopulator
        end

        expect {
          ContextFactory.set_populator(method_binding, AnotherPopulator)
        }.to change(ContextFactory.populators, :size).by(1)
      end
    end

    it 'should provide a default Populator when none specifically defined' do
      populator = ContextFactory.get_populator(method_binding)

      expect(populator).to be
      expect(populator).to be_a Populator
    end

    context 'providing populators' do
      before(:each) do
        class ASpecificPopulator
        end

        ContextFactory.set_populator(method_binding, ASpecificPopulator)
      end

      it 'should provide a specific Populator when one defined' do
        populator = ContextFactory.get_populator(method_binding)

        expect(populator).to_not be_nil
        expect(populator).to be_a ASpecificPopulator
      end
    end
  end
end
