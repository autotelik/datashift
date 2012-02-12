# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'

if(Guards::jruby?)

  require 'erb'
  require 'excel_loader'

  include DataShift

  describe 'Excel Loader' do

    before(:all) do
      db_connect( 'test_file' )    # , test_memory, test_mysql

      # load our test model definitions - Project etc
      require File.join($DataShiftFixturePath, 'test_model_defs')  
   
      # handle migration changes or reset of test DB
      migrate_up

      db_clear()    # todo read up about proper transactional fixtures


      @klazz = Project
      @assoc_klazz = Category
    end
  
    before(:each) do

      Project.delete_all
    
      %w{category_001 category_002 category_003}.each do |cat|
        @assoc_klazz.find_or_create_by_reference(cat)
      end


      MethodMapper.clear
      MethodMapper.find_operators( @klazz )
      MethodMapper.find_operators( @assoc_klazz )
    end
  
    it "should be able to create a new excel loader and load object" do
      loader = ExcelLoader.new( @klazz)
    
      loader.load_object.should_not be_nil
      loader.load_object.should be_is_a(@klazz)
      loader.load_object.new_record?.should be_true
    end
  
    it "should process a simple .xls spreedsheet" do
  
      loader = ExcelLoader.new(@klazz)
 
      count = @klazz.count
      loader.perform_load( $DataShiftFixturePath + '/SimpleProjects.xls')
  
      loader.loaded_count.should == (@klazz.count - count)
  
    end

    it "should process multiple associationss from single column" do

      @klazz.find_by_title('001').should be_nil
      count = @klazz.count

      loader = ExcelLoader.new(@klazz)
    
      loader.perform_load( $DataShiftFixturePath + '/ProjectsSingleCategories.xls')

      loader.loaded_count.should be > 3
      loader.loaded_count.should == (@klazz.count - count)

      {'001' => 2, '002' => 1, '003' => 3, '099' => 0 }.each do|title, expected|
        project = @klazz.find_by_title(title)

        project.should_not be_nil
        puts "#{project.inspect} [#{project.categories.size}]"
      
        project.should have(expected).categories
      end
    end

    it "should process multiple associations in excel spreedsheet" do
  
      loader = ExcelLoader.new(Project)
  
      count = Project.count
      loader.perform_load( $DataShiftFixturePath + '/ProjectsMultiCategories.xls')
  
      loader.loaded_count.should == (Project.count - count)
  
      {'004' => 3, '005' => 1, '006' => 0, '007' => 1 }.each do|title, expected|
        project = @klazz.find_by_title(title)
  
        project.should_not be_nil

        project.should have(expected).categories
      end
  
    end
  
    it "should process excel spreedsheet with extra undefined columns" do
      loader = ExcelLoader.new(Project)
      lambda {loader.perform_load( ifixture_file('BadAssociationName.xls') ) }.should_not raise_error
    end

    it "should NOT process excel spreedsheet with extra undefined columns when strict mode" do
      loader = ExcelLoader.new(Project)
      expect {loader.perform_load( ifixture_file('BadAssociationName.xls'), :strict => true)}.to raise_error(MappingDefinitionError)
    end

    it "should raise an error when mandatory columns missing" do
      loader = ExcelLoader.new(Project)
      expect {loader.perform_load($DataShiftFixturePath + '/ProjectsMultiCategories.xls', :mandatory => ['not_an_option', 'must_be_there'] )}.to raise_error(DataShift::MissingMandatoryError)
    end

    it "should provide facility to set default values", :focus => true do
      loader = ExcelLoader.new(Project)
      
      loader.set_default_value('value_as_string', 'some default text' )
      loader.set_default_value('value_as_double', 45.467 )
      loader.set_default_value('value_as_boolean', true )
      
      texpected = Time.now.to_s(:db)
      
      loader.set_default_value('value_as_datetime', texpected )
      
      #value_as_string	Value as Text	value as datetime	value_as_boolean	value_as_double	category

      loader.perform_load($DataShiftFixturePath + '/ProjectsSingleCategories.xls')
      
      p = Project.find_by_title( '099' )
      
      p.should_not be_nil
      
      p.value_as_string.should == 'some default text'
      p.value_as_double.should == 45.467
      p.value_as_boolean.should == true
      p.value_as_datetime.should == texpected

      p_no_defs = Project.first
      
      p_no_defs.value_as_string.should_not == 'some default text'
      p_no_defs.value_as_double.should_not == 45.467
      p_no_defs.value_as_datetime.should_not == texpected
      
    end
    
    it "should provide facility to set pre and post fix values" do
      loader = ExcelLoader.new(Project)
      
      loader.set_prefix('value_as_string', 'myprefix' )
      loader.set_postfix('value_as_string', 'my post fix' )
      
      #value_as_string	Value as Text	value as datetime	value_as_boolean	value_as_double	category

      loader.perform_load($DataShiftFixturePath + '/ProjectsSingleCategories.xls')
      
      p = Project.find_by_title( '001' )
      
      p.should_not be_nil
      
      p.value_as_string.should == 'myprefixDemo stringmy post fix'      
    end
    
   it "should provide facility to set default values via YAML configuration", :excel => true do
      loader = ExcelLoader.new(Project)
      
      loader.configure_from( File.join($DataShiftFixturePath, 'ProjectsDefaults.yml') )
      
      
      loader.perform_load( File.join($DataShiftFixturePath, 'ProjectsSingleCategories.xls') )
      
      p = Project.find_by_title( '099' )
      
      p.should_not be_nil
      
      p.value_as_string.should == "Default Project Value"    
    end


   it "should provide facility to over ride values via YAML configuration", :excel => true do
      loader = ExcelLoader.new(Project)
      
      loader.configure_from( File.join($DataShiftFixturePath, 'ProjectsDefaults.yml') )
      
      
      loader.perform_load( File.join($DataShiftFixturePath, 'ProjectsSingleCategories.xls') )
      
      Project.all.each {|p| p.value_as_double.should == 99.23546 }
    end
    
    
  end

else
  puts "WARNING: skipped excel_loader_spec : Requires JRUBY - JExcelFile requires JAVA"
end # jruby