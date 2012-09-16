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
  
describe 'Spree Variants Loader' do
      
  include SpecHelper
  extend SpecHelper  
      
  before(:all) do
    before_all_spree
  end

  before(:each) do

    begin
        
      before_each_spree
    
      @Product_klass.count.should == 0
      @Taxon_klass.count.should == 0
      @Variant_klass.count.should == 0
      
      MethodDictionary.clear
      
      # For Spree important to get instance methods too as Product delegates
      # many important attributes to Variant (master)
      MethodDictionary.find_operators( @Product_klass, :instance_methods => true )

      # want to test both lookup and dynamic creation - this Taxonomy should be found, rest created
      root = @Taxonomy_klass.create( :name => 'Paintings' )
    
      t = @Taxon_klass.new( :name => 'Landscape' )
      t.taxonomy = root
      t.save

      @Taxon_klass.count.should == 2
    
      @product_loader = DataShift::SpreeHelper::ProductLoader.new
    rescue => e
      puts e.inspect
      puts e.backtrace
    end
  end

  # Operation and results should be identical when loading multiple associations
  # if using either single column embedded syntax, or one column per entry.

  it "should load Products and create Variants from single column" do
    test_variants_creation('SpreeProducts.xls')
  end

  
  it "should load Products and create Variants from multiple column #{SpecHelper::spree_fixture('SpreeProductsMultiColumn.xls')}" do
    test_variants_creation('SpreeProductsMultiColumn.xls')
  end
  
  
  it "should load Products from multiple column csv as per .xls", :blah => true do
    test_variants_creation('SpreeProductsMultiColumn.csv')
  end
  
  
  def test_variants_creation( source )
    @Product_klass.count.should == 0
    @Variant_klass.count.should == 0
    
    @product_loader.perform_load( SpecHelper::spree_fixture(source), :mandatory => ['sku', 'name', 'price'] )
    
    expected_multi_column_variants
  end
  
  
  def expected_multi_column_variants
      
    # 3 MASTER products, 11 VARIANTS
    @Product_klass.count.should == 3
    @Variant_klass.count.should == 14

    p = @Product_klass.first

    p.sku.should == "DEMO_001"

    p.sku.should == "DEMO_001"
    p.price.should == 399.99
    p.description.should == "blah blah"
    p.cost_price.should == 320.00

    @Product_klass.all.select {|m| m.is_master.should == true  }


    # mime_type:jpeg mime_type:PDF mime_type:PNG
        
    p.variants.should have_exactly(3).items 
     
    p.option_types.should have_exactly(1).items # mime_type
    
    p.option_types[0].name.should == "mime_type"
    p.option_types[0].presentation.should == "Mime type"
        
    @Variant_klass.all[1].sku.should == "DEMO_001_1"
    @Variant_klass.all[1].price.should == 399.99

    # V1
    v1 = p.variants[0] 

    v1.sku.should == "DEMO_001_1"
    v1.price.should == 399.99    
    v1.count_on_hand.should == 12

    
    v1.option_values.should have_exactly(1).items # mime_type: jpeg
    v1.option_values[0].name.should == "jpeg"

    
    v2 = p.variants[1]
    v2.count_on_hand.should == 6
    v2.option_values.should have_exactly(1).items # mime_type: jpeg
    v2.option_values[0].name.should == "PDF"
    
    v2.option_values[0].option_type.should_not be_nil
    v2.option_values[0].option_type.position.should == 0
    
    
    v3 = p.variants[2]
    v3.count_on_hand.should == 7
    v3.option_values.should have_exactly(1).items # mime_type: jpeg
    v3.option_values[0].name.should == "PNG"
    
    @Variant_klass.last.price.should == 50.34
    @Variant_klass.last.count_on_hand.should == 18

    @product_loader.failed_objects.size.should == 0
  end
  
  # Composite Variant Syntax is option_type_A_name:value;option_type_B_name:value 
  # which creates a SINGLE Variant with 2 option types

  it "should create Variants with MULTIPLE option types from single column", :new => true  do
    @product_loader.perform_load( SpecHelper::spree_fixture('SpreeMultiVariant.csv'), :mandatory => ['sku', 'name', 'price'] )
     
    # Product 1)
    # 1 + 2) mime_type:jpeg,PDF;print_type:colour	 equivalent to (mime_type:jpeg;print_type:colour|mime_type:PDF;print_type:colour)
    # 3) mime_type:PNG	
    # 
    # Product 2
    # 4) mime_type:jpeg;print_type:black_white
    # 5) mime_type:PNG;print_type:black_white	
    # 
    # Product 3 
    # 6 +7) mime_type:jpeg;print_type:colour,sepia;size:large
    # 8) mime_type:jpeg;print_type:colour
    # 9) mime_type:PNG	
    # 9 + 10) mime_type:PDF|print_type:black_white

    prod_count = 3
    var_count = 10
    
    # plus 3 MASTER VARIANTS
    @Product_klass.count.should == prod_count
    @Variant_klass.count.should == prod_count + var_count

    p = @Product_klass.first
        
    p.variants_including_master.should have_exactly(4).items 
    p.variants.should have_exactly(3).items  
     
    p.variants.each { |v| v.option_values.each {|o| puts o.inspect } }        
    
    p.option_types.each { |ot| puts ot.inspect }
    p.option_types.should have_exactly(2).items # mime_type, print_type
    
    v1 = p.variants[0]
    v1.option_values.should have_exactly(2).items
    v1.option_values.collect(&:name).sort.should == ['colour','jpeg']

  end
  
  
  
end