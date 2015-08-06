# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
require File.dirname(__FILE__) + '/../spec_helper'

module DataShift

  describe 'Generator Base' do
    it 'should initialize' do
      expect(GeneratorBase.new).to be
    end

    context 'generation' do
      include_context 'ClearThenManageProject'

      let(:gb) { GeneratorBase.new }

      it 'should create a set of headers from a  Domain Model' do
        gb.collection_to_headers(project_collection)
      end
    end
  end
end
