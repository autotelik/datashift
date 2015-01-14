# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for base class Loader
#
require File.dirname(__FILE__) + '/spec_helper'

require 'erb'

describe 'Populator' do

  
  before(:each) do    
    @loader = DataShift::LoaderBase.new(Project)
    
    @populator = DataShift::Populator.new
    
  end
  
  it "should be able to create a new populator" do
    local_populator = DataShift::Populator.new
    local_populator.should_not be_nil
  end

  
  it "should be able to create and assign  populator as string to loader" do
    
    class AnotherPopulator
    end
    
    options = {:populator => 'AnotherPopulator' }
    
    local_loader = DataShift::LoaderBase.new(Project, true, nil, options)
    
    local_loader.populator.should_not be_nil
    local_loader.populator.should be_a AnotherPopulator
  end

  it "should be able to create and assign populator as class to loader" do
    
    class AnotherPopulator
    end
    
    options = {:populator => AnotherPopulator }
    
    local_loader = DataShift::LoaderBase.new(Project, true, nil, options)
    
    local_loader.populator.should_not be_nil
    local_loader.populator.should be_a AnotherPopulator
  end
  
  it "should process a string value against an assigment column" do

    column_heading = 'Value As String'
    value = 'Another Lazy fox '

    method_detail = DataShift::MethodDictionary.find_method_detail( Project, column_heading )
    
    expect(method_detail).to be_a  DataShift::MethodDetail
    
    pop_value, attributes = @populator.prepare_data(method_detail, value)
    
    pop_value.should == value
    attributes.should be_a Hash
    attributes.should be_empty
    
    # check for white space preservation
    value = 'Another Lazy fox'

    pop_value, attributes = @populator.prepare_data(method_detail, value)
    
    pop_value.should == value
    
  end

  it "should process a DSL string into a real hash" do

    str1  = "{:name => 'the_fox' }"
    
    x = DataShift::Populator::string_to_hash( str1 )
     
    expect(x).to  be_a Hash
    expect(x.size).to eq 1
    
    str2 =  "{:name => 'the_fox', 'occupation' => 'fantastic', :food => 'duck soup' }"
    
    x = DataShift::Populator::string_to_hash( str2 )
     
    expect(x.size).to eq 3
    expect(x.keys).to include 'food'
    expect(x['food']).to eq 'duck soup'
    
    str3 =  "{:cost_price => '13.45', :price => 23,  :sale_price => 4.23 }"
    
    x = DataShift::Populator::string_to_hash( str3 )

    expect(x.keys).to include 'price'
    expect(x['cost_price']).to eq '13.45'
    expect(x['price']).to eq 23
    expect(x['sale_price']).to eq 4.23
    
  end
  
  it "should process a string value against an assigment instance method" do
   
    value = 'Get up Lazy fox {:name => \'the_fox\' }'

    DataShift::MethodDictionary.find_operators( Milestone, :instance_methods => true  )
    
    DataShift::MethodDictionary.build_method_details( Milestone  )
      
    method_detail = DataShift::MethodDictionary.find_method_detail( Milestone, :title )
    
    method_detail.should_not be_nil
    
    pop_value, attrs = @populator.prepare_data(method_detail, value)
    
    expect(pop_value).to eq 'Get up Lazy fox '
    expect(attrs).to  be_a Hash
    expect(attrs.size).to eq 1
    expect(attrs.keys).to include 'name'
    expect(attrs['name']).to eq 'the_fox'
    
  end
  
end