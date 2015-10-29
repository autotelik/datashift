# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
require File.dirname(__FILE__) + '/../spec_helper'

module DataShift

  describe 'Context Factory' do

    include_context 'ClearThenManageProject'

    # got burnt by other tests failing if run after this, we are caching stuff in this class
    # that perissts across tests - so ContextFactory design probably a code smell
    after(:all) do
      ContextFactory.clear_populators
    end

    let(:model_method) { project_collection.search('value_as_string') }

    let(:method_binding) { MethodBinding.new('column_for_value_as_string', 0, model_method) }

    let(:another_populator) do
      class AnotherPopulator
      end

      AnotherPopulator
    end

    context 'configuring' do
      it 'can be configured to provide a specific Populator per operator' do
        expect {
          ContextFactory.set_populator(method_binding, another_populator)
        }.to change(ContextFactory.populators, :size).by(1)
      end
    end

    context 'providing populators' do
      before(:each) do
        ContextFactory.clear_populators

        ContextFactory.set_populator(method_binding, another_populator)
      end

      it 'should provide a default Populator when none specifically defined' do

        mb = MethodBinding.new('value_as_boolean', 0, project_collection.search('value_as_boolean'))

        populator = ContextFactory.get_populator(mb)

        expect(populator).to be
        expect(populator).to be_a Populator
      end

      it 'should provide a specific Populator when one defined' do
        populator = ContextFactory.get_populator(method_binding)

        expect(populator).to_not be_nil
        expect(populator).to be_a AnotherPopulator
      end
    end
  end
end
