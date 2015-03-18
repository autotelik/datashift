# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for base class Loader
#
require File.dirname(__FILE__) + '/spec_helper'

module DataShift

  describe 'Context Factory' do

    include_context "ClearThenManageProject"


    context "prepare data" do

      before(:each) do
        @loader = DataShift::LoaderBase.new(Project)
      end

      let(:populator) { DataShift::Populator.new }

      it "should provide a default Popualtoirm when no specifically defined" do

        pending "refactoring"

        populator = ContextFactory::get_populator(method_binding)

        expect(populator).to_not be_nil
        expect(populator).to be_a Populator
      end

      it "should provide a specific Populator when one defined" do

        pending "refactoring"
        class AnotherPopulator
        end

        options = {:populator => AnotherPopulator }

        populator = ContextFactory::get_populator(method_binding)

        expect(populator).to_not be_nil
        expect(populator).to be_a AnotherPopulator
      end

    end

  end
end