# To change this template, choose Tools | Templates
# and open the template in the editor.

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'excel'

describe 'Excel Proxy' do

  before(:each) do
    @excel = Excel.new
  end

  it "can open an existing spreadsheet" do

    sheet = @excel.open( ifixture_file('ProjectsSingleCategories.xls') )

    sheet.should_not be_nil
  end
  
  it "can create new un-named worksheet" do
    sheet1 = @excel.create_worksheet

    sheet1.name.should == "Worksheet1"
  end
  
  it "can create multiple un-named worksheets" do
    sheet1 = @excel.create_worksheet
    sheet2 = @excel.create_worksheet
    sheet1.name.should == "Worksheet1"
    sheet2.name.should == "Worksheet2"
  end
  
  it "can create new named worksheet" do

    sheet = @excel.create_worksheet( :name => "daft punk")
    sheet.name.should == "daft punk"
    
    sheet2 = @excel.create_worksheet( :name => "underworld")
    sheet2.name.should == "underworld"
  end
  
  it "ensures name of worksheet sanitized" do
    sheet = @excel.create_worksheet( :name => "daft: ?punk")
    sheet.name.should == "daft punk"
    
    sheet = @excel.create_worksheet( :name => "under[]world")
    sheet.name.should == "underworld"
  end
  
  it "can create multiple named worksheets" do

    @excel.create_worksheet( :name => "underworld")
    @excel.create_worksheet( :name => "jeff mills")  
    @excel.create_worksheet( :name => "autechre")
    @excel.create_worksheet( :name => "swarms")
        
    @excel.worksheets.should have_exactly(4).items
  end
  
  it "can access a worksheet by index" do

    @excel.create_worksheet( :name => "underworld")
    @excel.create_worksheet( :name => "jeff mills")  
    @excel.create_worksheet( :name => "autechre")
        
    @excel.worksheets[0].name.should == "underworld" 
    @excel.worksheets[2].name.should == "autechre" 
  end
  
  
  it "can access a worksheet by ID" do

    @excel.create_worksheet( :name => "daft punk")  
    @excel.create_worksheet( :name => "underworld")
    
    @excel.worksheet(0).name.should == "daft punk" 
    
    @excel.worksheet(1).name.should == "underworld"
   
  end
  
  it "can add data to a specific row and column" do

    @excel.create_worksheet( :name => "underworld")
    
    @excel[0, 1] = "born slippy"      
    @excel[0, 1].should == "born slippy"
    
    @excel[1, 23] = 23.0
    @excel[1, 23].should == 23.0
    
    @excel[0, 5] = true
    @excel[0, 5].should == true
  end
  
  it "can ask a row what index it is" do

    @excel.create_worksheet( :name => "underworld")
    
    @excel[3, 0] = "do i know who i am?"      
    @excel[28, 0] = "who am i?"
    
    r1 = @excel.row(3)
    r1[0].should == "do i know who i am?"     
    r1.idx.should == 3    #  idx (0-based)

    r2 = @excel.row(28)
    r2[0].should ==  "who am i?"
    r2.idx.should == 28   #  idx (0-based)
  end
  
  it "can iterate over the rows in a worksheet" do

    sheet = @excel.create_worksheet
    
    @excel[0, 1] = 12.30
    @excel[1, 1] = 25.30
    @excel[3, 1] = 4
    
    sheet.each do |row|
      row[0] = "A#{row.idx}"
    end
    
    @excel[0, 0].should == "A0"
    @excel[1, 0].should == "A1"
    
    # pending for JRuby ... spreadsheet iterates from 0 to max row, probably
    # dynamically creating rows that have never been referenced .. 
    @excel[2, 0].should == "A2" unless DataShift::Guards.jruby?
    
    @excel[3, 0].should == "A3"
    
    @excel[0, 1].should == 12.30
    @excel[1, 1].should == 25.30
    @excel[2, 1].should satisfy {|x| x == "" || x == nil }
    @excel[3, 1].should == 4
  end
 
  
  it "can iterate over the cells in a row"do

    sheet = @excel.create_worksheet
    
    values = [ 'hello world', 12.30, "", 4 ]
    
    values.each_with_index do |v, i| 
      @excel[0, i] = v
    end

    row = @excel.row(0)
     
    row.each { |col| col.should == values.shift  }
  end
  
  
  it "can support bools" do
    pending("reading back value sometimes returns "" when cell was set to false")
  end

  it "can write an Excel file" do
    @excel = Excel.new

    sheet1 = @excel.create_worksheet

    @excel.create_worksheet( :name => "underworld")
    
    @excel[0, 1] = "born slippy"      
    @excel[0, 1].should == "born slippy"
    
    expected = result_file('it_can_save_an_excel_file.xls')
    
    @excel.write( expected )
    
    File.exists?(expected).should be_true
    
  end
end

