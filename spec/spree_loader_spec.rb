# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Summer 2011
#
# License::   MIT - Free, OpenSource
#
# Details::   Specification for Spree aspect of datashift gem.
#
#             Provides Loaders and rake tasks specifically tailored for uploading or exporting
#             Spree Products, associations and Images
#
require File.dirname(__FILE__) + '/spec_helper'

require 'spree_helper'
require 'product_loader'

include DataShift
  
describe 'SpreeLoader' do

      
  before(:all) do
    SpecHelper::before_all_spree
  end

  before(:each) do

    begin
    
      include SpecHelper
      extend SpecHelper
      
      before_each_spree
    
      @klass.count.should == 0
      @Taxon_klass.count.should == 0
      @Variant_klass.count.should == 0
      
      MethodDictionary.clear
      MethodDictionary.find_operators( @klass )

      # want to test both lookup and dynamic creation - this Taxonomy should be found, rest created
      root = @Taxonomy_klass.create( :name => 'Paintings' )
    
      @Taxon_klass.create( :name => 'Landscape', :taxonomy => root )

      @Taxon_klass.count.should == 2
    
      @product_loader = DataShift::SpreeHelper::ProductLoader.new
    rescue => e
      puts e.inspect
      puts e.backtrace
    end
  end


  it "should process a simple .xls spreadsheet" do

    @zone_klass.delete_all

    loader = ExcelLoader.new(@zone_klass)
    
    loader.perform_load( SpecHelper::spree_fixture('SpreeZoneExample.xls') )

    loader.loaded_count.should == @zone_klass.count
  end

  it "should process a simple csv file" do

    @zone_klass.delete_all

    loader = CsvLoader.new(@zone_klass)

    loader.perform_load( SpecHelper::spree_fixture('SpreeZoneExample.csv') )

    loader.loaded_count.should == @zone_klass.count
  end
  

  # Loader should perform identically regardless of source, whether csv, .xls etc
  
  it "should load basic Products .xls via Spree loader" do
    test_basic_product('SpreeProductsSimple.xls')
  end

  it "should load basic Products from .csv via Spree loader", :csv => true do
    test_basic_product('SpreeProductsSimple.csv')
  end

  it "should raise an error for missing file" do
    lambda { test_basic_product('SpreeProductsSimple.txt') }.should raise_error BadFile
  end

  it "should raise an error for unsupported file types" do
    lambda { test_basic_product('SpreeProductsDefaults.yml') }.should raise_error UnsupportedFileType
  end
  
  def test_basic_product( source )
    
    @product_loader.perform_load( SpecHelper::spree_fixture(source), :mandatory => ['sku', 'name', 'price'] )

    @klass.count.should == 3

    @product_loader.failed_objects.size.should == 0
    @product_loader.loaded_objects.size.should == 3

    @product_loader.loaded_count.should == @klass.count

    p = @klass.first
    
    p.sku.should == "SIMPLE_001"
    p.price.should == 345.78
    p.name.should == "Simple Product for AR Loader"
    p.description.should == "blah blah"
    p.cost_price.should == 320.00
    p.option_types.should have_exactly(1).items
    p.count_on_hand.should == 12
    
    @klass.last.option_types.should have_exactly(2).items
    @klass.last.count_on_hand.should == 23
  end

  
  it "should support default values for Spree Products loader", :fail => true do
   
    @expected_time =  Time.now.to_s(:db) 
    
    @product_loader.set_default_value('available_on', @expected_time)
    @product_loader.set_default_value('cost_price', 1.0 )
    @product_loader.set_default_value('meta_description', 'super duper meta desc.' )
    @product_loader.set_default_value('meta_keywords', 'techno dubstep d&b' )
      

    @product_loader.set_prefix('sku', 'SPEC_')
      
    test_default_values

  end

  it "should support default values from config for Spree Products loader", :fail => true do
   
    @product_loader.configure_from(  SpecHelper::spree_fixture('SpreeProductsDefaults.yml') )
    
    @product_loader.set_prefix('sku', 'SPEC_')
      
    test_default_values

  end
  
  def test_default_values
    @product_loader.perform_load( SpecHelper::spree_fixture('SpreeProductsMandatoryOnly.xls'), :mandatory => ['sku', 'name', 'price'] )
    
    @klass.count.should == 3

    @product_loader.failed_objects.size.should == 0
    @product_loader.loaded_objects.size.should == 3
    
    p = @klass.first
    
    p.sku.should == "SPEC_SIMPLE_001"
      
    @klass.all { |p|
      p.sku.should.include "SPEC_"
      p.cost_price = 1.0
      p.available_on.should == @expected_time
      p.meta_description.should == 'super duper meta desc.'
      p.meta_keywords.should == 'techno dubstep d&b'
    }
  end

  # Operation and results should be identical when loading multiple associations
  # if using either single column embedded syntax, or one column per entry.

  it "should load Products and create Variants from single column", :fail => true do
    test_variants_creation('SpreeProducts.xls')
  end

  
  it "should load Products and create Variants from multiple column" do
    test_variants_creation('SpreeProductsMultiColumn.xls')
  end
  
  def test_variants_creation( source )
    @klass.count.should == 0
    @Variant_klass.count.should == 0
    
    @product_loader.perform_load( SpecHelper::spree_fixture(source), :mandatory => ['sku', 'name', 'price'] )
    
    expected_multi_column_variants
  end
  
  
  def expected_multi_column_variants
      
    # 3 MASTER products, 11 VARIANTS
    @klass.count.should == 3
    @Variant_klass.count.should == 14

    p = @klass.first

    p.sku.should == "DEMO_001"

    p.sku.should == "DEMO_001"
    p.price.should == 399.99
    p.description.should == "blah blah"
    p.cost_price.should == 320.00

    @klass.all.select {|m| m.is_master.should == true  }

    p.variants.should have_exactly(3).items  # count => 12|6|7
  
    @Variant_klass.all[1].sku.should == "DEMO_001_0"
    @Variant_klass.all[1].price.should == 399.99

    v = p.variants[0] 

    v.sku.should == "DEMO_001_0"
    v.price.should == 399.99
    v.count_on_hand.should == 12

    p.variants[1].count_on_hand.should == 6
    p.variants[2].count_on_hand.should == 7

    @Variant_klass.last.price.should == 50.34
    @Variant_klass.last.count_on_hand.should == 18

    @product_loader.failed_objects.size.should == 0
  end

  ##################
  ### PROPERTIES ###
  ##################
  
  # Operation and results should be identical when loading multiple associations
  # if using either single column embedded syntax, or one column per entry.

  it "should load Products and multiple Properties from single column", :props => true do
    test_properties_creation( 'SpreeProducts.xls' )
  end

  it "should load Products and multiple Properties from multiple column", :props => true do
    test_properties_creation( 'SpreeProductsMultiColumn.xls' )
  end

  def test_properties_creation( source )

    # want to test both lookup and dynamic creation - this Prop should be found, rest created
    @Property_klass.create( :name => 'test_pp_001', :presentation => 'Test PP 001' )

    @Property_klass.count.should == 1

    @product_loader.perform_load( SpecHelper::spree_fixture(source), :mandatory => ['sku', 'name', 'price'] )
    
    expected_multi_column_properties
  
  end
  
  def expected_multi_column_properties
    # 3 MASTER products, 11 VARIANTS
    @klass.count.should == 3
    @Variant_klass.count.should == 14

    @klass.first.properties.should have_exactly(1).items

    p3 = @klass.all.last

    p3.properties.should have_exactly(3).items

    p3.properties.should include @Property_klass.find_by_name('test_pp_002')

    # Test the optional text value got set on assigned product property
    p3.product_properties.select {|p| p.value == 'Example free value' }.should have_exactly(1).items

  end
  
  ##############
  ### TAXONS ###
  ##############

  # Operation and results should be identical when loading multiple associations
  # if using either single column embedded syntax, or one column per entry.

  it "should load Products and multiple Taxons from single column", :taxon => true do
    test_taxon_creation( 'SpreeProducts.xls' )
  end

  it "should load Products and multiple Taxons from multiple columns", :taxons => true do
    test_taxon_creation( 'SpreeProductsMultiColumn.xls' )
  end

  def test_taxon_creation( source )

    # we want to test both find and find_or_create so should already have an object
    # for find
    @Taxonomy_klass.count.should == 1
    @Taxon_klass.count.should == 2
          
    @product_loader.perform_load( SpecHelper::spree_fixture(source), :mandatory => ['sku', 'name', 'price'] )
    
    expected_multi_column_taxons
  end
  
  def expected_multi_column_taxons
      
    #puts @Taxonomy_klass.all.collect( &:name).inspect
    #puts @Taxon_klass.all.collect( &:name).inspect
    
    # Paintings alreadyexisted and had 1 child Taxon (Landscape)
    # 2 nested Taxon (Paintings>Nature>Seascape) created under it so expect Taxonomy :
    
    # WaterColour	
    # Oils	
    # Paintings >Nature>Seascape + >Landscape	
    # Drawings

    @Taxonomy_klass.count.should == 4
    @Taxon_klass.count.should == 7

    @klass.first.taxons.should have_exactly(2).items
    @klass.last.taxons.should have_exactly(2).items

    p2 = @Variant_klass.find_by_sku("DEMO_002").product

    # Paintings	Oils	Paintings>Nature>Seascape

    #puts p2.taxons.collect(&:name).inspect
      
    p2.taxons.should have_exactly(4).items
    
    p2.taxons.collect(&:name).sort.should == ['Nature','Oils','Paintings','Seascape']
     
    paint_parent = @Taxonomy_klass.find_by_name('Paintings')
         
    paint_parent.taxons.should have_exactly(4).items # 3 children + all Taxonomies have a root Taxon
    
    paint_parent.taxons.collect(&:name).sort.should == ['Landscape','Nature','Paintings','Seascape']
    
    tn = @Taxon_klass.find_by_name('Nature')    # child with children 
    ts = @Taxon_klass.find_by_name('Seascape')  # last child

    ts.should_not be_nil
    tn.should_not be_nil
    
    p2.taxons.collect( &:id ).should include(ts.id)
    p2.taxons.collect( &:id ).should include(tn.id)
    
    puts tn.inspect
    puts ts.inspect
     
    tn.parent.id.should == paint_parent.root.id
    ts.parent.id.should == tn.id
    
    tn.children.should have_exactly(1).items
    ts.children.should have_exactly(0).items

 
  end
  
  
  # REPEAT THE WHOLE TEST SUITE VIA CSV

  it "should load Products from single column csv as per .xls" do
    test_variants_creation('SpreeProducts.csv')
    
    expected_multi_column_properties
    
    expected_multi_column_taxons
  end
  
  
  it "should load Products from multiple column csv as per .xls" do
    test_variants_creation('SpreeProductsMultiColumn.csv')
    
    expected_multi_column_properties
    
    expected_multi_column_taxons
  end

  
  it "should raise exception when mandatory columns missing from .xls", :ex => true do
    expect {@product_loader.perform_load($SpreeNegativeFixturePath + '/SpreeProdMissManyMandatory.xls', :mandatory => ['sku', 'name', 'price'] )}.to raise_error(DataShift::MissingMandatoryError)
  end
  

  it "should raise exception when single mandatory column missing from .xls", :ex => true do
    expect {@product_loader.perform_load($SpreeNegativeFixturePath + '/SpreeProdMiss1Mandatory.xls', :mandatory => 'sku' )}.to raise_error(DataShift::MissingMandatoryError)
  end

  it "should raise exception when mandatory columns missing from .csv", :ex => true do
    expect {@product_loader.perform_load($SpreeNegativeFixturePath + '/SpreeProdMissManyMandatory.csv', :mandatory => ['sku', 'name', 'price'] )}.to raise_error(DataShift::MissingMandatoryError)
  end
  

  it "should raise exception when single mandatory column missing from .csv", :ex => true do
    expect {@product_loader.perform_load($SpreeNegativeFixturePath + '/SpreeProdMiss1Mandatory.csv', :mandatory => 'sku' )}.to raise_error(DataShift::MissingMandatoryError)
  end
  
end