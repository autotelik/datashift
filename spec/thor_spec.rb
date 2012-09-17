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
require 'thor/runner'

require File.dirname(__FILE__) + '/spec_helper'

describe 'Thor high level command line tasks' do

  include SpecHelper
  extend SpecHelper   
        
  before(:all) do
    DataShift::load_commands
  end
  
  before(:each) do
  end
  
  #thor datashift:export:csv -m, --model=MODEL -r, --result=RESULT              ...
  #thor datashift:export:excel -m, --model=MODEL -r, --result=RESULT            ...
  #thor datashift:generate:excel -m, --model=MODEL -r, --result=RESULT          ...
  #thor datashift:import:csv -i, --input=INPUT -m, --model=MODEL                ...
  #thor datashift:import:excel -i, --input=INPUT -m, --model=MODEL              ...
  #thor datashift:paperclip:attach -a, --attachment-klass=ATTACHMENT_KLASS -f, -...
  #thor datashift:spree:attach_images -i, --input=INPUT                         ...
  #thor datashift:spree:images -i, --input=INPUT                                ...
  #thor datashift:spree:products -i, --input=INPUT                              ...
  #thor datashift:spreeboot:cleanup                                             ...
  #thor datashift:spreereports:no_image                                         ...
  #thor datashift:tools:zip -p, --path=PATH -r, --results=RESULTS               ...

  it "should list available datashift thor tasks" do
    x = capture(:stdout){ Thor::Runner.start(["list"]) }
    x.should =~ /.+datashift.+\n---------\n/
    x.should =~ / excel -i/
    x.should =~ / products -i/
  end

  it "should be able to run simple excel import CLI" do
    x = capture(:stdout){ Thor::Runner.start(["datashift:import:excel", '-m', 'Spree::Zone', '-i', SpecHelper::spree_fixture('SpreeZoneExample.xls')]) }
    
    puts x
  end
  
  
end