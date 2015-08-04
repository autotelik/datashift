# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for base class Loader
#
require File.dirname(__FILE__) + '/spec_helper'

require 'erb'

module DataShift
  describe 'LoaderBase' do
    let(:loader) { LoaderBase.new }

    it 'should be able to create an empty loader with nil load object' do
      expect(loader.load_object).to be_nil
      expect(loader.file_name).to eq ''
      expect(loader.doc_context).to be_a(DocContext)
      expect(loader.binder).to be_a(Binder)
    end

    it 'should be able to set the filename ot load' do
      file_loader =  LoaderBase.new file_name: 'Test.csv'
      expect(file_loader.file_name).to eq 'Test.csv'
    end
  end

end
