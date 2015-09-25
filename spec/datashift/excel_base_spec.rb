require File.dirname(__FILE__) + '/../spec_helper'

module DataShift

  module ExcelBase

    describe 'ExcelBase' do
      before(:each) do
        include DataShift::ExcelBase
        extend DataShift::ExcelBase
      end

      let(:filename) { ifixture_file('ProjectsSingleCategories.xls') }

      it 'should provide fast access to an Excel instance' do
        expect( start_excel(filename, 0) ).to be_a DataShift::Excel
      end

      let(:sheet_name) { 'RspecTester' }

      it 'should enable us to add a named worksheet' do
        start_excel(filename, 0, sheet_name: sheet_name)
        expect( excel ).to be_a DataShift::Excel

        expect( sheet ).to be_a Spreadsheet::Worksheet
        expect( sheet.name ).to eq sheet_name
      end

      context 'Once opened' do
        before(:each) do
          start_excel(filename, 0)
        end

        it 'should provide fast access to current sheet' do
          expect( sheet ).to be_a Spreadsheet::Worksheet
        end

        it 'should parse headers' do
          parse_headers( sheet )
        end
      end
    end
  end
end
