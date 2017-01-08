require_relative '../spec_helper'

module DataShift

  module ExcelBase

    describe 'ExcelBase' do
      before(:each) do
        include DataShift::ExcelBase
        extend DataShift::ExcelBase
      end

      let(:file_name) { ifixture_file('ProjectsSingleCategories.xls') }

      it 'should provide fast access to an Excel instance' do
        expect( start_excel(Project) ).to be_a DataShift::Excel
      end

      it 'should provide fast access to open an existing Excel file' do
        expect( open_excel(file_name) ).to be_a DataShift::Excel
      end

      let(:sheet_name) { 'RspecTester' }

      it 'should enable us to add a named worksheet' do
        start_excel(Project, sheet_name: sheet_name)
        expect( excel ).to be_a DataShift::Excel

        expect( sheet ).to be_a Spreadsheet::Worksheet
        expect( sheet.name ).to eq sheet_name
      end

      it 'should enable us to add a named worksheet to existing Excel file' do
        open_excel(file_name, sheet_name: sheet_name)
        expect( excel ).to be_a DataShift::Excel

        expect( sheet ).to be_a Spreadsheet::Worksheet
        expect( sheet.name ).to eq sheet_name
      end

      context 'Once opened' do

        before(:each) do
          open_excel(file_name, sheet_number: 0)
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
