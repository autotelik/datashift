# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Summer 2011
#
# License::   MIT - Free, OpenSource
#
# Details::   Specification for Spree aspect of datashift gem.
#
#             Tests the method mapping aspect, such as that we correctly identify 
#             Spree Product attributes and associations
#             
require File.dirname(__FILE__) + '/spec_helper'

require 'spree_helper'
require 'product_loader'

include DataShift
  
describe 'SpreeLoader' do

  before(:all) do

    # we are not a Spree project, nor is it practical to externally generate
    # a complete Spree application for testing so we implement a mini migrate/boot of our own
    SpreeHelper.load()            # require Spree gems

    # key to YAML db e.g  test_memory, test_mysql
    db_connect( 'test_spree_standalone' )    

    SpreeHelper.boot            # create a sort-of Spree app
    
    SpreeHelper.migrate_up      # create an sqlite Spree database on the fly

    @klazz = Product

    # Reset main tables - TODO should really purge properly, or roll back a transaction
    [OptionType, OptionValue, Product, Property, Variant, Taxonomy, Taxon, Zone].each { |x| x.delete_all }
  end

  before(:each) do
    MethodDictionary.clear
    MethodDictionary.find_operators( @klazz )
  end

  
  it "should populate operators for a Spree Product" do
  
    MethodDictionary.has_many.should_not be_empty
    MethodDictionary.belongs_to.should_not be_empty
    MethodDictionary.assignments.should_not be_empty

    assign = MethodDictionary.assignments_for(@klazz)

    assign.should include('available_on')   # Example of a simple column

    MethodDictionary.assignments[@klazz].should include('available_on')

    has_many_ops = MethodDictionary.has_many_for(@klazz)

    has_many_ops.should include('properties')   # Product can have many properties

    MethodDictionary.has_many[@klazz].should include('properties')

    btf = MethodDictionary.belongs_to_for(@klazz)

    btf.should include('tax_category')    # Example of a belongs_to assignment

    MethodDictionary.belongs_to[@klazz].should include('tax_category')

    MethodDictionary.column_types[@klazz].size.should == @klazz.columns.size
  end


  it "should find method details correctly for different forms of a column name" do

    MethodDictionary.build_method_details( @klazz )
        
    ["available On", 'available_on', "Available On", "AVAILABLE_ON"].each do |format|

      method_details = MethodDictionary.find_method_detail( @klazz, format )

      method_details.operator.should == 'available_on'
      method_details.operator_for(:assignment).should == 'available_on'

      method_details.operator_for(:belongs_to).should be_nil
      method_details.operator_for(:has_many).should be_nil

      method_details.col_type.should_not be_nil
      method_details.col_type.name.should == 'available_on'
      method_details.col_type.default.should == nil
      method_details.col_type.sql_type.should include 'datetime'   # works on mysql and sqlite
      method_details.col_type.type.should == :datetime
    end
  end

  it "should populate method details correctly for has_many forms of association name" do

    MethodDictionary.has_many[@klazz].should include('product_option_types')

    MethodDictionary.build_method_details( @klazz )
        
    ["product_option_types", "product option types", 'product Option_types', "ProductOptionTypes", "Product_Option_Types"].each do |format|
      method_detail = MethodDictionary.find_method_detail( @klazz, format )

      method_detail.should_not be_nil

      method_detail.operator_for(:has_many).should eq('product_option_types')
      method_detail.operator_for(:belongs_to).should be_nil
      method_detail.operator_for(:assignment).should be_nil
    end
  end


  it "should populate method details correctly for assignment operators (none columns on #{@klazz})" do

    MethodDictionary.find_operators( @klazz, :reload => true, :instance_methods => true )

    MethodDictionary.build_method_details( @klazz )
        
    # Example of delegates i.e. cost_price column on Variant, delegated to Variant by Product

    MethodDictionary.assignments[@klazz].should include('cost_price')
    MethodDictionary.assignments[@klazz].should include('sku')


    count_on_hand = MethodDictionary.find_method_detail( @klazz, 'count on hand' )
    count_on_hand.should_not be_nil
    count_on_hand.operator.should == 'count_on_hand'

    method = MethodDictionary.find_method_detail( @klazz, 'sku' )
    method.should_not be_nil
    method.operator.should == 'sku'
  end

  it "should enable assignment via operators for none columns on #{@klazz}" do

    MethodDictionary.find_operators( @klazz, :reload => true, :instance_methods => true )

    MethodDictionary.build_method_details( @klazz )
        
    klazz_object = @klazz.new

    klazz_object.should be_new_record

    # we can use method details to populate a new AR object, essentailly same as
    # klazz_object.send( count_on_hand.operator, 2)
    count_on_hand = MethodDictionary.find_method_detail( @klazz, 'count on hand' )

    count_on_hand.assign( klazz_object, 2 )
    klazz_object.count_on_hand.should == 2

    count_on_hand.assign( klazz_object, 5 )
    klazz_object.count_on_hand.should == 5

    method = MethodDictionary.find_method_detail( @klazz, 'sku' )
    method.should_not be_nil

    method.operator.should == 'sku'

    method.assign( klazz_object, 'TEST_SK 001')
    klazz_object.sku.should == 'TEST_SK 001'

  end

  it "should enable assignment to has_many association on new object" do
 
    MethodDictionary.build_method_details( @klazz )
        
    method_detail = MethodDictionary.find_method_detail( @klazz, 'taxons' )

    method_detail.operator.should == 'taxons'

    klazz_object = @klazz.new

    klazz_object.taxons.size.should == 0

    # NEW ASSOCIATION ASSIGNMENT

    # assign via the send operator directly on load object
    klazz_object.send( method_detail.operator ) << Taxon.new

    klazz_object.taxons.size.should == 1

    klazz_object.send( method_detail.operator ) << [Taxon.new, Taxon.new]
    klazz_object.taxons.size.should == 3

    # Use generic assignment on method detail - expect has_many to use << not =
    method_detail.assign( klazz_object, Taxon.new )
    klazz_object.taxons.size.should == 4

    method_detail.assign( klazz_object, [Taxon.new, Taxon.new])
    klazz_object.taxons.size.should == 6
  end

  it "should enable assignment to has_many association using existing objects" do

    MethodDictionary.find_operators( @klazz )

    MethodDictionary.build_method_details( @klazz )
        
    method_detail = MethodDictionary.find_method_detail( @klazz, 'product_properties' )

    method_detail.operator.should == 'product_properties'

    klazz_object = @klazz.new

    ProductProperty.new(:property => @prop1)

    # NEW ASSOCIATION ASSIGNMENT
    klazz_object.send( method_detail.operator ) << ProductProperty.new

    klazz_object.product_properties.size.should == 1

    klazz_object.send( method_detail.operator ) << [ProductProperty.new, ProductProperty.new]
    klazz_object.product_properties.size.should == 3

    # Use generic assignment on method detail - expect has_many to use << not =
    method_detail.assign( klazz_object, ProductProperty.new(:property => @prop1) )
    klazz_object.product_properties.size.should == 4

    method_detail.assign( klazz_object, [ProductProperty.new(:property => @prop2), ProductProperty.new(:property => @prop3)])
    klazz_object.product_properties.size.should == 6

  end

  
end