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

    # key to YAML db e.g  test_memory, test_mysql
    db_connect( 'test_spree_standalone' )    
    
    # See errors  #<NameError: uninitialized constant RAILS_CACHE> when doing save (AR without Rails)
    # so copied this from ... Rails::Initializer.initialize_cache
    Object.const_set "RAILS_CACHE", ActiveSupport::Cache.lookup_store( :memory_store )

    RAILS_CACHE = ActiveSupport::Cache.lookup_store( :memory_store )

    # we are not a Spree project, nor is it practical to externally generate
    # a complete Spree application for testing so we implement a mini migrate/boot of our own
    Spree.load()          # require Spree gems
    Spree.boot            # create a sort-of Spree app
    
    Spree.migrate_up      # create an sqlite Spree database on the fly

    @klazz = Product

    $SpreeFixturePath = File.join($DataShiftFixturePath, 'spree')
    
    $SpreeNegativeFixturePath = File.join($DataShiftFixturePath, 'negative')

  end
  
  def spree_fix( source)
    File.join($SpreeFixturePath, source)
  end

  before(:each) do

    MethodMapper.clear
    MethodDictionary.find_operators( @klazz )

    # Reset main tables - TODO should really purge properly, or roll back a transaction
    [OptionType, OptionValue, Product, Property, Variant, Taxonomy, Taxon, Zone].each { |x| x.delete_all }
        
    Product.count.should == 0
    
    Taxon.count.should == 0

    # want to test both lookup and dynamic creation - this Taxonomy should be found, rest created
    root = Taxonomy.create( :name => 'Paintings' )
    Taxon.create( :name => 'Landscape', :taxonomy => root )

    Taxon.count.should == 2
    
        
    @product_loader = DataShift::Spree::ProductLoader.new
  end


  it "should process a simple .xls spreadsheet" do

    Zone.delete_all

    loader = ExcelLoader.new(Zone)
    
    loader.perform_load( spree_fix('SpreeZoneExample.xls') )

    loader.loaded_count.should == Zone.count
  end

  it "should process a simple csv file" do

    Zone.delete_all

    loader = CsvLoader.new(Zone)

    loader.perform_load( spree_fix('SpreeZoneExample.csv') )

    loader.loaded_count.should == Zone.count
  end
  

  # Loader should perform identically regardless of source, whether csv, .xls etc
  
  it "should load basic Products .xls via Spree loader", :focus => true do
    test_basic_product('SpreeProductsSimple.xls')
  end

  it "should load basic Products from .csv via Spree loader" do
    test_basic_product('SpreeProductsSimple.csv')
  end

  it "should raise an error for unsupported file types" do
    lambda { test_basic_product('SpreeProductsSimple.xml') }.should raise_error UnsupportedFileType
  end
  
  def test_basic_product( source )
    
    @product_loader.perform_load( spree_fix(source), :mandatory => ['sku', 'name', 'price'] )

    Product.count.should == 3

    @product_loader.failed_objects.size.should == 0
    @product_loader.loaded_objects.size.should == 3

    @product_loader.loaded_count.should == Product.count

    p = Product.first
    
    p.sku.should == "SIMPLE_001"
    p.price.should == 345.78
    p.name.should == "Simple Product for AR Loader"
    p.description.should == "blah blah"
    p.cost_price.should == 320.00
    p.option_types.should have_exactly(1).items
    p.count_on_hand.should == 12
    
    Product.last.option_types.should have_exactly(2).items
    Product.last.count_on_hand.should == 23
  end


  # Operation and results should be identical when loading multiple associations
  # if using either single column embedded syntax, or one column per entry.

  it "should load Products and create Variants from single column" do
    test_variants_creation('SpreeProducts.xls')
  end

  
  it "should load Products and create Variants from multiple column" do
    test_variants_creation('SpreeProductsMultiColumn.xls')
  end
  
  def test_variants_creation( source )
    @product_loader.perform_load( spree_fix(source), :mandatory => ['sku', 'name', 'price'] )
    
    expected_multi_column_variants
  end
  
  
  def expected_multi_column_variants
      
    # 3 MASTER products, 11 VARIANTS
    Product.count.should == 3
    Variant.count.should == 14

    p = Product.first

    p.sku.should == "DEMO_001"

    p.sku.should == "DEMO_001"
    p.price.should == 399.99
    p.description.should == "blah blah"
    p.cost_price.should == 320.00

    Product.all.select {|m| m.is_master.should == true  }

    p.variants.should have_exactly(3).items
  
    Variant.all[1].sku.should == "DEMO_001_0"
    Variant.all[1].price.should == 399.99

    v = p.variants[0]

    v.sku.should == "DEMO_001_0"
    v.price.should == 399.99
    v.count_on_hand.should == 12

    p.variants[1].count_on_hand.should == 6
    p.variants[2].count_on_hand.should == 7

    Variant.last.price.should == 50.34
    Variant.last.count_on_hand.should == 18

    @product_loader.failed_objects.size.should == 0
  end


  # Operation and results should be identical when loading multiple associations
  # if using either single column embedded syntax, or one column per entry.

  it "should load Products and multiple Properties from single column" do
    test_properties_creation( 'SpreeProducts.xls' )
  end

  it "should load Products and multiple Properties from multiple column" do
    test_properties_creation( 'SpreeProductsMultiColumn.xls' )
  end

  def test_properties_creation( source )

    # want to test both lookup and dynamic creation - this Prop should be found, rest created
    Property.create( :name => 'test_pp_001', :presentation => 'Test PP 001' )

    Property.count.should == 1

    @product_loader.perform_load( spree_fix(source), :mandatory => ['sku', 'name', 'price'] )
    
    expected_multi_column_properties
  
  end
  
  def expected_multi_column_properties
    Property.count.should == 4

    Product.first.properties.should have_exactly(1).items

    p3 = Product.all.last

    p3.properties.should have_exactly(3).items

    p3.properties.should include Property.find_by_name('test_pp_002')

    # Test the optional text value got set on assigned product property
    p3.product_properties.select {|p| p.value == 'Example free value' }.should have_exactly(1).items

  end

  # Operation and results should be identical when loading multiple associations
  # if using either single column embedded syntax, or one column per entry.

  it "should load Products and multiple Taxons from single column" do
    test_taxon_creation( 'SpreeProducts.xls' )
  end

  it "should load Products and multiple Taxons from multiple columns" do
    test_taxon_creation( 'SpreeProductsMultiColumn.xls' )
  end

  def test_taxon_creation( source )

    @product_loader.perform_load( spree_fix(source), :mandatory => ['sku', 'name', 'price'] )
    
    expected_multi_column_taxons
  end
  
  def expected_multi_column_taxons
      
    Taxonomy.count.should == 4
    Taxon.count.should == 5

    Product.first.taxons.should have_exactly(2).items
    Product.last.taxons.should have_exactly(1).items

    p2 = Product.all[1]

    p2.taxons.should have_exactly(3).items

    t = Taxon.find_by_name('Oils')

    t.should_not be_nil
    
    p2.taxons.collect( &:id ).should include(t.id)

  end

  it "should load Products with assoicated image", :img => true do
    
    @product_loader.perform_load( spree_fix('SpreeProductsWithImages.csv'), :mandatory => ['sku', 'name', 'price'] )
     
    p = Product.find_by_sku( "DEMO_001")
    
    p.images.should have_exactly(1).items
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

  it "should load Products with assoicated image" do
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