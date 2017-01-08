# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for base class Loader
#
require_relative '../spec_helper'

describe 'Headers' do
  before(:each) do
  end

  context 'No Initial Headers' do
    it 'should be able to populate empty' do
      expect(DataShift::Headers.new( :csv, 0 )).to be
    end

    it 'should be able to identify the source and index' do
      h = DataShift::Headers.new( :csv, 2 )
      expect(h.source).to eq :csv
      expect(h.idx).to eq 2
    end

    it 'should act like an Array' do
      h = DataShift::Headers.new( :csv, 0 )

      expect(h.respond_to?(:each)).to eq true
    end

    it 'should be able to add headers as if using an Array' do
      h = DataShift::Headers.new( :csv, 0 )

      expect(h.size).to eq 0
      expect(h.empty?).to eq true

      h << 'sku'

      expect(h.size).to eq 1
      expect(h.empty?).to eq false
    end

    it 'should be able to read headers as if using an Array' do
      h = DataShift::Headers.new( :csv, 0 )

      expect(h.size).to eq 0
      expect(h.empty?).to eq true

      h << 'sku'

      expect(h.size).to eq 1
      expect(h.empty?).to eq false
    end

  end
end
