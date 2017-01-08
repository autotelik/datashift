# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Oct 2011
# License::   MIT
#
# Details::   Specs for high level apsects of DataShift library
#
require_relative '../spec_helper'

require 'datashift/version'

describe 'DataShift' do
  before(:each) do
  end

  it 'should provide gem version' do
    expect(DataShift::VERSION).to be_a String
  end

  it 'should provide gem name' do
    expect(DataShift.gem_name).to eq 'datashift'
  end

  it 'should provide root_path' do
    expect(DataShift.root_path).to_not be_empty
  end

  it 'should provide a log' do
    class Blah
      include DataShift::Logging

      def try_me
        logger.info 'hello datashift spec'
      end
    end

    b = Blah.new

    b.logger.info 'try me'

    b.try_me
  end

  it 'should provide quick way to create exception class' do
    DataShift::DataShiftException.generate( 'BadRspecError')

    e = DataShift::BadRspecError.new('my new exception  class')

    expect(e).to be
    expect(e.message).to eq 'my new exception  class'
  end
end
