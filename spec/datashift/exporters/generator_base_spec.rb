# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
require_relative '../../spec_helper'

module DataShift

  describe 'Generator Base' do

    before(:each) do
      DataShift::Exporters::Configuration.reset
    end

    it 'should initialize' do
      expect(GeneratorBase.new).to be
    end
=begin Headers moved into Schema
    context 'generation' do
      include_context 'ClearThenManageProject'

      let(:gb) { x = GeneratorBase.new; Headers.klass_to_headers(Project); x }

      it 'should create an instance of Headers from a Domain Model' do
        expect(gb.headers).to be_a Headers
        expect(gb.headers[0]).to be_a Header
      end

      it 'sets the source of the Headers to the Domain Model' do
        expect(gb.headers.source).to eq Project
      end

      it 'should create one header per Domain Model attribute' do
        expect(gb.headers.size).to eq Project.new.serializable_hash.keys.size
      end

      it 'headers are the model method operator name' do
        expect(gb.headers[0]).to be_a Header
        expect(gb.headers[0].source).to be_a String
      end

    end
=end
  end
end
