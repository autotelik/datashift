# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for base class Loader
#
require File.dirname(__FILE__) + '/spec_helper'

require 'paperclip/attachment_loader'
  
Paperclip.options[:command_path] = "/usr/local/bin/"

describe 'PaperClip Bulk Loader' do

  
  include DataShift::Logging
  
  module Paperclip
    module Interpolations

      # Returns the Rails.root constant.
      def rails_root attachment, style_name
        '.'
      end
    end
  end
  
  before(:each) do    
    @attachment_klass = Digital
    
    @common_options = {:verbose => true }
    
    @attachment_path = File.join(fixtures_path, 'images')
  end
  
  it "should create a new paperclip loader and define attachment class" do 
    loader = DataShift::Paperclip::AttachmentLoader.new(@attachment_klass, nil, @common_options)
    
    loader.load_object_class.should == Digital
    loader.load_object.should be_a Digital
        
    loader.attach_to_klass.should == nil  
  end

  it "should create loader,define attachment class and define class to attach to" do
             
    opts = { :attach_to_klass => Owner }.merge(@common_options)
    
    loader = DataShift::Paperclip::AttachmentLoader.new(@attachment_klass, nil, opts)
    
    loader.attach_to_klass.should == Owner
  end
  
  it "should bulk load from a directory file system" do
   
    # these names should be included in the attachment file name somewhere
    ["DEMO_001", "DEMO_002", "DEMO_003", "DEMO_004"].each do |n|
      Owner.create( :name => n )
    end
     
    opts = {  :attach_to_klass => Owner, 
      :attach_to_find_by_field => :name,
      :attach_to_field => :digitals,
      :split_file_name_on => '_'
    }.merge(@common_options)
    
    loader = DataShift::Paperclip::AttachmentLoader.new(@attachment_klass, nil, opts)
 
    loader.process_from_filesystem(@attachment_path, opts)
  end
  
  it "should handle not beign able to find matching record" do
   
    # these names should be included in the attachment file name somewhere
    names = ["DEMO_001", "DEMO_002", "DEMO_003", "DEMO_004"]
    
    names.each do |n|
      Owner.create( :name => n )
    end
     
    opts = { :attach_to_klass => Owner, :attach_to_find_by_field => :name }.merge(@common_options)
    
    
    loader = DataShift::Paperclip::AttachmentLoader.new(@attachment_klass, nil, opts)
 
    loader.process_from_filesystem(@attachment_path, opts)
    
    expect(Dir.glob("MissingAttachmentRecords/*.jpeg", File::FNM_CASEFOLD).size).to eq names.size
  end
  
end