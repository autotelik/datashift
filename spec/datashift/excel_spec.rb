require File.join(File.dirname(__FILE__), '/../spec_helper')

require 'excel'

module DataShift

  describe 'Excel Proxy' do
    let(:excel) { Excel.new }

    it 'should reject .xlsx until spreedsheet gem supports it' do
      expect { excel.open( ifixture_file('ProjectsSingleCategories.xlsx') ) }.to raise_error Ole::Storage::FormatError
    end

    it 'can open an existing spreadsheet' do
      sheet = excel.open( ifixture_file('ProjectsSingleCategories.xls') )

      expect(sheet).to_not be_nil
    end

    it 'can create new un-named worksheet' do
      sheet1 = excel.create_worksheet

      expect( sheet1.name).to eq 'Worksheet1'
    end

    it 'can create multiple un-named worksheets' do
      sheet1 = excel.create_worksheet
      sheet2 = excel.create_worksheet
      expect(sheet1.name).to eq 'Worksheet1'
      expect(sheet2.name).to eq 'Worksheet2'
    end

    it 'can create new named worksheet' do
      sheet = excel.create_worksheet( name: 'daft punk')
      expect( sheet.name).to eq 'daft punk'

      sheet2 = excel.create_worksheet( name: 'underworld')
      expect( sheet2.name).to eq 'underworld'
    end

    it 'can sanitize worksheet names as per Excel spec' do
      include DataShift::ExcelBase
      extend DataShift::ExcelBase

      #    name.gsub(/[\[\]:\*\/\\\?]/, '

      expect(sanitize_sheet_name('aute?chre')).to eq 'autechre'
      expect(sanitize_sheet_name('?autechre')).to eq 'autechre'
      expect(sanitize_sheet_name('aute?chre?')).to eq 'autechre'

      expect(sanitize_sheet_name('daft: ?punk')).to eq 'daft punk'
      expect(sanitize_sheet_name('guy call[]ed *Gerald')).to eq 'guy called Gerald'

      expect(sanitize_sheet_name('guy called */Gerald')).to eq 'guy called Gerald'
    end

    # Pending - inject create_worksheet method into Spreadsheet gem
    if DataShift::Guards.jruby?
      it 'ensures name of worksheet sanitized' do
        sheet = excel.create_worksheet( name: 'daft: ?punk')
        expect( sheet.name).to eq 'daft punk'

        sheet = excel.create_worksheet( name: 'under[]world')
        expect( sheet.name).to eq 'underworld'
      end
    end

    it 'can create multiple named worksheets' do
      excel.create_worksheet( name: 'underworld')
      excel.create_worksheet( name: 'jeff mills')
      excel.create_worksheet( name: 'autechre')
      excel.create_worksheet( name: 'swarms')

      expect(excel.worksheets.size).to eq 4
    end

    it 'can access a worksheet by index' do
      excel.create_worksheet( name: 'underworld')
      excel.create_worksheet( name: 'jeff mills')
      excel.create_worksheet( name: 'autechre')

      expect(excel.worksheets[0].name).to eq 'underworld'
      expect(excel.worksheets[2].name).to eq 'autechre'
    end

    it 'can access a worksheet by ID' do
      excel.create_worksheet( name: 'daft punk')
      excel.create_worksheet( name: 'underworld')

      expect(excel.worksheet(0).name).to eq 'daft punk'

      expect(excel.worksheet(1).name).to eq 'underworld'
    end

    it 'can add data to a specific row and column' do
      excel.create_worksheet( name: 'underworld')

      excel[0, 1] = 'born slippy'
      expect(excel[0, 1]).to eq 'born slippy'

      excel[1, 23] = 23.0
      expect(excel[1, 23]).to eq 23.0

      excel[0, 5] = true
      expect( excel[0, 5]).to eq true
    end

    it 'can ask a row what index it is' do
      excel.create_worksheet( name: 'underworld')

      excel[3, 0] = 'do i know who i am?'
      excel[28, 0] = 'who am i?'

      r1 = excel.row(3)
      expect(r1[0]).to eq 'do i know who i am?'
      expect(r1.idx).to eq 3    #  idx (0-based)

      r2 = excel.row(28)
      expect(r2[0]).to eq 'who am i?'
      expect(r2.idx).to eq 28   #  idx (0-based)
    end

    it 'can iterate over the rows in a worksheet' do
      sheet = excel.create_worksheet

      excel[0, 1] = 12.30
      excel[1, 1] = 25.30
      excel[3, 1] = 4

      sheet.each do |row|
        row[0] = "A#{row.idx}"
      end

      expect(excel[0, 0]).to eq 'A0'
      expect(excel[1, 0]).to eq 'A1'

      # pending for JRuby ... spreadsheet iterates from 0 to max row, probably
      # dynamically creating rows that have never been referenced ..
      expect(excel[2, 0]).to eq 'A2' unless DataShift::Guards.jruby?

      expect(excel[3, 0]).to eq 'A3'

      expect(excel[0, 1]).to eq 12.30
      expect(excel[1, 1]).to eq 25.30
      expect(excel[2, 1]).to satisfy { |x| x == '' || x.nil? }
      expect(excel[3, 1]).to eq 4
    end

    it 'can iterate over the cells in a row' do
      sheet = excel.create_worksheet

      values = ['hello world', 12.30, '', 4]

      values.each_with_index do |v, i|
        excel[0, i] = v
      end

      row = excel.row(0)

      row.each { |col| expect(col).to eq values.shift }
    end

    # it "can support bools" do
    #  pending "reading back value sometimes returns "" when cell was set to false"

    # sheet = excel.create_worksheet

    # end

    it 'can write an Excel file' do
      excel = Excel.new

      sheet1 = excel.create_worksheet

      excel.create_worksheet( name: 'underworld')

      excel[0, 1] = 'born slippy'
      expect(excel[0, 1]).to eq 'born slippy'

      expected = result_file('it_can_save_an_excel_file.xls')

      excel.write( expected )

      expect(File.exist?(expected)).to eq true
    end
  end

end
