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
      
      MethodDictionary.clear
      
      # For Spree important to get instance methods too as Product delegates
      # many important attributes to Variant (master)
      MethodDictionary.find_operators( @Product_klass, :instance_methods => true )
    
      @product_loader = DataShift::SpreeHelper::ProductLoader.new
    rescue => e
      puts e.inspect
      puts e.backtrace
    end
  end


  # Operation and results should be identical when loading multiple associations
  # if using either single column embedded syntax, or one column per entry.

  it "should load Products and multiple Taxons from single column", :taxons => true, :fail => true do
    test_taxon_creation( 'SpreeProducts.xls' )
  end

  it "should load Products and multiple Taxons from multiple columns .xls", :taxons => true do
    test_taxon_creation( 'SpreeProductsMultiColumn.xls' )
  end

  it "should load Products and multiple Taxons from multiple columns CSV", :taxons => true do
    test_taxon_creation( 'SpreeProductsMultiColumn.csv' )
  end
  
  def test_taxon_creation( source )

    # we want to test both find and find_or_create so should already have an object
    # for find
    # want to test both lookup and dynamic creation - this Taxonomy should be found, rest created
    root = @Taxonomy_klass.create( :name => 'Paintings' )
    
    x = root.taxons.create( :name => 'Landscape')
    root.root.children << x
    
  
    @Taxonomy_klass.count.should == 1
    @Taxon_klass.count.should == 2
    
    root.root.children.should have_exactly(1).items
    root.root.children[0].name.should == 'Landscape'
    
    @product_loader.perform_load( SpecHelper::spree_fixture(source), :mandatory => ['sku', 'name', 'price'] )
    
    expected_multi_column_taxons
  end
  
  def expected_multi_column_taxons
      

    # Paintings already existed and had 1 child Taxon (Landscape)
    # 2 nested Taxon (Paintings>Nature>Seascape) created under it so expect Taxonomy :
    
    # WaterColour	
    # Oils	
    # Paintings >Nature>Seascape + Paintings>Landscape	
    # Drawings
    
    @Taxonomy_klass.all.collect(&:name).sort.should == ["Drawings", "Oils", "Paintings", "WaterColour"]
       

    @Taxonomy_klass.count.should == 4
    @Taxon_klass.count.should == 7

    @Product_klass.count.should == 3
    
    p = @Variant_klass.find_by_sku("DEMO_001").product

    p.taxons.should have_exactly(2).items
    p.taxons.collect(&:name).sort.should == ['Paintings','WaterColour']
     
    p2 = @Variant_klass.find_by_sku("DEMO_002").product

    p2.taxons.should have_exactly(4).items    
    p2.taxons.collect(&:name).sort.should == ['Nature','Oils','Paintings','Seascape']
     
    paint_parent = @Taxonomy_klass.find_by_name('Paintings')
    
       
    puts paint_parent.taxons.collect(&:name).sort.inspect
     
    paint_parent.taxons.should have_exactly(4).items # 3 children + all Taxonomies have a root Taxon
    
    paint_parent.taxons.collect(&:name).sort.should == ['Landscape','Nature','Paintings','Seascape']
    
    tn = @Taxon_klass.find_by_name('Nature')    # child with children 
    ts = @Taxon_klass.find_by_name('Seascape')  # last child

    ts.should_not be_nil
    tn.should_not be_nil
    
    p2.taxons.collect( &:id ).should include(ts.id)
    p2.taxons.collect( &:id ).should include(tn.id)

     
    tn.parent.id.should == paint_parent.root.id
    ts.parent.id.should == tn.id
    
    tn.children.should have_exactly(1).items
    ts.children.should have_exactly(0).items
 
  end
  
  it "should load nested Taxons correctly even when same names from csv", :taxons => true do
    
    @Taxonomy_klass.delete_all
    @Taxon_klass.delete_all    
    
    @Taxonomy_klass.count.should == 0
    @Taxon_klass.count.should == 0 
    
    @product_loader.perform_load( SpecHelper::spree_fixture('SpreeProductsComplexTaxons.xls') )
    
    expected_nested_multi_column_taxons
  end

  it "should load nested Taxons correctly even when same names from xls", :taxons => true do
    
    @Taxonomy_klass.delete_all
    @Taxon_klass.delete_all    
    
    @Taxonomy_klass.count.should == 0
    @Taxon_klass.count.should == 0 
    
    @product_loader.perform_load( SpecHelper::spree_fixture('SpreeProductsComplexTaxons.csv') )
    
    expected_nested_multi_column_taxons
    
  end
  
  def expected_nested_multi_column_taxons
    # Expected :
    # 2  Paintings>Landscape
    # 1  WaterColour
    # 1  Paintings
    # 1  Oils
    # 2  Drawings>Landscape            - test same name for child (Paintings)
    # 1  Paintings>Nature>Landscape    - test same name for child of a child
    # 1  Landscape	
    # 0  Drawings>Landscape                - test same structure should be reused
    # 2  Paintings>Nature>Seascape->Cliffs - test only the leaf node is created, rest re-used
    # 1  Drawings>Landscape>Bristol        - test a new leaf node created when parent name is same over different taxons
      
    #puts @Taxonomy_klass.all.collect(&:name).sort.inspect
    @Taxonomy_klass.count.should == 5 
    
    @Taxonomy_klass.all.collect(&:name).sort.should == ['Drawings', 'Landscape', 'Oils', 'Paintings','WaterColour']
    
    @Taxonomy_klass.all.collect(&:root).collect(&:name).sort.should == ['Drawings', 'Landscape', 'Oils', 'Paintings','WaterColour']
   
    taxons = @Taxon_klass.all.collect(&:name).sort
    
    #puts "#{taxons.inspect} (#{taxons.size})"
    
    @Taxon_klass.count.should == 12
   
    taxons.should == ['Bristol', 'Cliffs', 'Drawings', 'Landscape', 'Landscape', 'Landscape', 'Landscape', 'Nature', 'Oils', 'Paintings', 'Seascape','WaterColour']

    # drill down acts_as_nested_set ensure structures correct
    
    # Paintings - Landscape
    #           - Nature
    #                 - Landscape
    #                 - Seascape
    #                     - Cliffs
    painting_onomy = @Taxonomy_klass.find_by_name('Paintings')

    painting_onomy.taxons.should have_exactly(6).items
    painting_onomy.root.child?.should be false
     
    painting = painting_onomy.root
    
    painting.children.should have_exactly(2).items
    painting.children.collect(&:name).sort.should == ["Landscape", "Nature"]
    
    painting.descendants.should have_exactly(5).items
    
    lscape = {}
    nature = nil
    
    @Taxon_klass.each_with_level(painting.self_and_descendants) do |t, i|
    
      
      if(t.name == 'Nature')
        nature = t
        i.should == 1
        t.children.should have_exactly(2).items
        t.children.collect(&:name).should == ["Landscape", "Seascape"]

        t.descendants.should have_exactly(3).items
        t.descendants.collect(&:name).sort.should == ["Cliffs", "Landscape", "Seascape"]
    
      elsif(t.name == 'Landscape')
        lscape[i] = t
      end
    end

    nature.should_not be_nil
    
    lscape.size.should be 2
    lscape[1].name.should == 'Landscape'
    lscape[1].parent.id.should == painting.id

    lscape[2].name.should == 'Landscape'
    lscape[2].parent.id.should == nature.id
    
 
    seascape = @Taxon_klass.find_by_name('Seascape') 
    seascape.children.should have_exactly(1).items
    seascape.leaf?.should be false
    

    cliffs = @Taxon_klass.find_by_name('Cliffs') 
    cliffs.children.should have_exactly(0).items
    cliffs.leaf?.should be true

    @Taxon_klass.find_by_name('Seascape').ancestors.collect(&:name).sort.should == ["Nature", "Paintings"]
    
    # Landscape appears multiple times, under different parents
    @Taxon_klass.find_all_by_name('Landscape').should have_exactly(4).items

    # Check the correct Landscape used, Drawings>Landscape>Bristol
    
    drawings = @Taxonomy_klass.find_by_name('Drawings')
    
    drawings.taxons.should have_exactly(3).items
    
    dl = drawings.taxons.find_by_name('Landscape').children
    
    
    dl.should have_exactly(1).items
  
    b = dl.find_by_name('Bristol')
    
    b.children.should have_exactly(0).items
    b.ancestors.collect(&:name).sort.should == ["Drawings", "Landscape"]

    # empty top level taxons
    ['Oils', 'Landscape'].each do |t|
      tx = @Taxonomy_klass.find_by_name(t)
      tx.taxons.should have_exactly(1).items
      tx.root.name.should == t
      tx.root.children.should have_exactly(0).items
      tx.root.leaf?.should be true
    end
    

  end
  
  
end