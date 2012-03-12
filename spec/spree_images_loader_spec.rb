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
      
      MethodDictionary.clear
      MethodDictionary.find_operators( @klass )
    
      @product_loader = DataShift::SpreeHelper::ProductLoader.new
    rescue => e
      puts e.inspect
      puts e.backtrace
    end
  end


  it "should load Products with associated image" do
   
    @product_loader.perform_load( SpecHelper::spree_fixture('SpreeProductsWithImages.csv'), :mandatory => ['sku', 'name', 'price'] )
     
    p = @klass.find_by_name("Demo Product for AR Loader")
    
    p.name.should == "Demo Product for AR Loader"
    p.images.should have_exactly(1).items
    
    @klass.all.each {|p| p.images.should have_exactly(1).items }
  end
  
  
  it "should be able to assign Images to preloaded Products" do
    
    @product_loader.perform_load( SpecHelper::spree_fixture('SpreeProductsMultiColumn.csv'), :mandatory => ['sku', 'name', 'price'] )
  
    @Image_klass.all.size.should == 0
    
    @klass.all.each {|p| p.images.should have_exactly(0).items }
    
    loader = DataShift::SpreeHelper::ImageLoader.new
    
  end
  
end