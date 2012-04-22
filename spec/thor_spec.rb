# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     April 20121
#
# License::   MIT - Free, OpenSource
#
# Details::   Specification for Thor tasks supplied with datashift
#
require 'thor'
require 'thor/group'


require File.dirname(__FILE__) + '/spec_helper'

require 'spree_helper'

load 'products_images.thor'

include DataShift
  
describe 'Thor high level command line tasks' do

  before(:each) do
  end

  
  it "should be able to run spree loaders from a simple command line task" do
    Datashift::Spree.start(["products"])
  end

    
end