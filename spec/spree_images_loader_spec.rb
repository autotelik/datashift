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
      MethodDictionary.find_operators( @klass )
    
      @product_loader = DataShift::SpreeHelper::ProductLoader.new
    rescue => e
      puts e.inspect
      puts e.backtrace
    end
  end


  it "should load Products with associated image from CSV" do
    
    # In >= 1.1.0 Image moved to master Variant from Product
   
    options = {:mandatory => ['sku', 'name', 'price']}
    
    options[:force_inclusion] = ['sku', 'images'] if(SpreeHelper::version.to_f > 1 )
    
    @product_loader.perform_load( SpecHelper::spree_fixture('SpreeProductsWithImages.csv'), options )
     
    @Image_klass.all.each_with_index {|i, x| puts "RESULT IMAGE #{x}", i.inspect }
        
    p = @Product_klass.find_by_name("Demo Product for AR Loader")
    
    p.name.should == "Demo Product for AR Loader"
    
    p.images.should have_exactly(1).items
    p.master.images.should have_exactly(1).items
    
    @Product_klass.all.each {|p| p.images.should have_exactly(1).items }
    
    @Image_klass.count.should == 3
  end
  
  
  it "should load Products with associated image" do
   
    options = {:mandatory => ['sku', 'name', 'price']}
    
    options[:force_inclusion] = ['sku', 'images'] if(SpreeHelper::version.to_f > 1 )
    
    @product_loader.perform_load( SpecHelper::spree_fixture('SpreeProductsWithImages.xls'), options )
     
    @Image_klass.all.each_with_index {|i, x| puts "RESULT IMAGE #{x}", i.inspect }
        
    p = @klass.find_by_name("Demo Product for AR Loader")
    
    p.name.should == "Demo Product for AR Loader"
    p.images.should have_exactly(1).items
    
    @Product_klass.all.each {|p| p.images.should have_exactly(1).items }
     
    @Image_klass.count.should == 3

  end
  
  it "should be able to assign Images to preloaded Products", :fail => true  do
    
    MethodDictionary.find_operators( @Image_klass )
    
    @Product_klass.count.should == 0
    
    @product_loader.perform_load( SpecHelper::spree_fixture('SpreeProducts.xls'))
    
    @Image_klass.all.size.should == 0

    # force inclusion means add to operator list even if not present
    options = { :verbose => true, :force_inclusion => ['sku', 'attachment'] } if(SpreeHelper::version.to_f > 1 )
    
    loader = DataShift::SpreeHelper::ImageLoader.new(nil, options)
    
    loader.perform_load( SpecHelper::spree_fixture('SpreeImages.xls'), options )
    
    @Image_klass.all.each_with_index {|i, x| puts "RESULT IMAGE #{x}", i.inspect }
     
    @Image_klass.count.should == 3
        
    p = @klass.find_by_name("Demo Product for AR Loader")
    
    p.name.should == "Demo Product for AR Loader"
    
    p.images.should have_exactly(1).items
    
    @Product_klass.all.each {|p| p.images.should have_exactly(1).items }
   
  end
  
end