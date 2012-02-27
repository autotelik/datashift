# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for MethodMapper aspect of Active Record Loader
#             MethodMapper provides the bridge between 'strings' e.g column headings
#             and a classes different types of assignment operators
#
require File.dirname(__FILE__) + '/spec_helper'
    
describe 'Method Mapping' do

  before(:all) do
    db_connect( 'test_file' )    # , test_memory, test_mysql
    
    # load our test model definitions - Project etc
    require ifixture_file('test_model_defs')  

    migrate_up
  end
  
  before(:each) do
    MethodDictionary.clear
    
    MethodDictionary.find_operators( Project )
    MethodDictionary.find_operators( Milestone )
    
    
    MethodDictionary.build_method_details( Project )
    MethodDictionary.build_method_details( Milestone )
    
  end
 
  it "should find a set of methods based on a list of column names" do
     pending("key API - map column headers to set of methods")
     
    @method_mapper.map_inbound_to_methods( load_object_class, @headers )
  end


end