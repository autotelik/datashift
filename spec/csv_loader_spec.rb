# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for Excel aspect of Active Record Loader
#
require File.dirname(__FILE__) + '/spec_helper'

require 'erb'
require 'excel_loader'

describe 'CSV Loader' do

  before(:all) do
    
    # load our test model definitions - Project etc
    require File.join($DataShiftFixturePath, 'test_model_defs')  
       
    db_connect( 'test_file' )    # , test_memory, test_mysql
    migrate_up
    @klazz = Project
  end
  
  before(:each) do
    MethodMapper.clear
    MethodDictionary.find_operators( @klazz )
    MethodDictionary.find_operators( @assoc_klazz )
  end

end