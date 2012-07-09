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
  
describe 'SpreeImageLoading' do

  include SpecHelper
  extend SpecHelper
      
  before(:all) do
    before_all_spree
  end

  before(:each) do

    begin
    
      before_each_spree

      @Image_klass.count.should == 0
      @Product_klass.count.should == 0
      
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


  it "should create Image from path in Product loading column from CSV", :fail => true do
       
    options = {:mandatory => ['sku', 'name', 'price']}
    
    @product_loader.perform_load( SpecHelper::spree_fixture('SpreeProductsWithImages.csv'), options )
     
    @Image_klass.all.each_with_index {|i, x| puts "SPEC CHECK IMAGE #{x}", i.inspect }
        
    p = @Product_klass.find_by_name("Demo Product for AR Loader")
    
    p.name.should == "Demo Product for AR Loader"
    
    p.images.should have_exactly(1).items
    p.master.images.should have_exactly(1).items
    
    @Product_klass.all.each {|p| p.images.should have_exactly(1).items }
    
    @Image_klass.count.should == 3
  end
  
  
  it "should create Image from path in Product loading column from Excel", :fail => true do
   
    options = {:mandatory => ['sku', 'name', 'price']}
    
    @product_loader.perform_load( SpecHelper::spree_fixture('SpreeProductsWithImages.xls'), options )
        
    p = @klass.find_by_name("Demo Product for AR Loader")
    
    p.name.should == "Demo Product for AR Loader"
    p.images.should have_exactly(1).items
    
    @Product_klass.all.each {|p| p.images.should have_exactly(1).items }
     
    @Image_klass.count.should == 3

  end
  
  it "should be able to assign Images to preloaded Products"  do
  
    pending "Currently functionality supplied by a thor task images()"
    
    MethodDictionary.find_operators( @Image_klass )
    
    @Product_klass.count.should == 0
    
    @product_loader.perform_load( SpecHelper::spree_fixture('SpreeProducts.xls'))
    
    @Image_klass.all.size.should == 0

    loader = DataShift::SpreeHelper::ImageLoader.new(nil, options)
    
    loader.perform_load( SpecHelper::spree_fixture('SpreeImages.xls'), options )
   
  end
  
end