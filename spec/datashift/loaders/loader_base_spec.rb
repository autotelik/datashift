# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for base class Loader
#
require_relative '../../spec_helper'

require 'erb'

module DataShift
  describe 'LoaderBase' do
    let(:loader) { LoaderBase.new }

    it 'should be able to create an empty loader with basic load object' do
      expect(loader.load_object).to be_a DataShift::LoadObject
      expect(loader.file_name).to eq ''
      expect(loader.doc_context).to be_a(DocContext)
      expect(loader.binder).to be_a(Binder)
    end

    it 'should be able to set the file_name ot load' do
      loader.file_name = 'Test.csv'
      expect(loader.file_name).to eq 'Test.csv'
    end
  end

end
