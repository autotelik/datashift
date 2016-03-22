# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
require File.dirname(__FILE__) + '/../spec_helper'

module DataShift

  describe 'Generator Base' do

    before(:each) do
      DataShift::Exporters::Configuration.reset
    end

    it 'should initialize' do
      expect(GeneratorBase.new).to be
    end

    context 'generation' do
      include_context 'ClearThenManageProject'

      let(:gb) { GeneratorBase.new }

      it 'should create a set of headers from a  Domain Model' do
        gb.klass_to_headers(Project)
        expect(gb.headers.size).to eq Project.new.serializable_hash.keys.size
      end

      it 'headers are the model method operator name' do
        gb.klass_to_headers(Project)
        expect(gb.headers[0]).to be_a String
      end

    end
  end
end
