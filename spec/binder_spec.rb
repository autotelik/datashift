# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::   Specs for Binder aspect of Active Record Loader
#             Binder provides the bridge between 'strings' e.g column headings
#             and a classes different types of assignment operators/associations
#
require File.join(File.dirname(__FILE__), 'spec_helper')

module DataShift

  describe 'Binder Mapper' do

    include_context "ClearThenManageProject"

    let(:method_mapper)   { Binder.new }

    let (:headers)        { [:value_as_string, :owner, :value_as_boolean, :value_as_double] }

    it "should find a set of methods based on a list of column symbols" do
      bindings = method_mapper.map_inbound_headers( Project, headers )
      expect(bindings.size).to eq 4
    end

    it "should leave nil in set of methods when no such operator" do

      headers = [:value_as_string, :owner, :bad_no_such_column, :value_as_boolean, :value_as_double, :more_rubbish_as_nil]

      bindings = method_mapper.map_inbound_headers( Project, headers )

      expect(bindings.size).to eq 6

      expect(bindings[2]).to be_a NoMethodBinding
      expect(bindings[5]).to be_a NoMethodBinding

      expect(bindings[0]).to be_a MethodBinding

    end

    it "should map a list of column names to a set of method details", :fail => true do

      headers = %w{ value_as_double value_as_string bad_no_such_column value_as_boolean  }

      bindings = method_mapper.map_inbound_headers( Project, headers )

      expect(bindings.size).to eq 4

      expect(bindings[2]).to be_a NoMethodBinding

      expect(bindings[0]).to be_a  MethodBinding
      expect(bindings.last).to be_a  MethodBinding
    end

    it "should populate a method detail instance based on column and database info" do

      headers = [:value_as_string, :owner, :value_as_boolean, :value_as_double]

      bindings = method_mapper.map_inbound_headers( Project, headers )

      expect(bindings.size).to eq 4

      expect(bindings[0]).to be_a  MethodBinding

      headers.each_with_index do |c, i|
        expect(bindings[i].inbound_index).to eq i
        expect(bindings[i].inbound_column.index).to eq i
      end

    end

    it "should map between user name and domain model attribute" do

      headers = [ "Value as string", :value_as_string, "value_as boolean", 'Value_As_Double']

      operators = %w{ value_as_string value_as_string value_as_boolean value_as_double }

      bindings = method_mapper.map_inbound_headers( Project, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |c, i|
        expect(bindings[i].valid?).to eq true
        expect(bindings[i].inbound_index).to eq  i
        expect(bindings[i].inbound_name).to eq  c.to_s
        expect(bindings[i].operator).to eq operators[i]
      end

    end


    it "should map between user name and domain model has_one association" do

      # Project has_one  :owner
      headers = [ "owner", 'Owner', :owner]

      operators = %w{ owner owner owner }

      bindings = method_mapper.map_inbound_headers( Project, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |c, i|
        expect(bindings[i].valid?).to eq true
        expect(bindings[i].inbound_index).to eq  i
        expect(bindings[i].inbound_name).to eq  c.to_s
        expect(bindings[i].operator).to eq operators[i]
      end

    end

    it "should map between user name and domain model has_many association" do

      # Project has_many :loader_releases
      headers = [ "loader_releases", 'Loader Releases', :loader_releases]

      operators = %w{ loader_releases loader_releases loader_releases }

      bindings = method_mapper.map_inbound_headers( Project, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |c, i|
        expect(bindings[i].valid?).to eq true
        expect(bindings[i].inbound_index).to eq  i
        expect(bindings[i].inbound_name).to eq  c.to_s
        expect(bindings[i].operator).to eq operators[i]
      end
    end

    it "should parse header for where  fields and make available through inbound_column" do

      # Owner has a name and belongs_to Project which has a title i.e lookup on title
      headers = ["project:title"]

      bindings = method_mapper.map_inbound_headers( Owner, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |c, i|
        expect(bindings[i].valid?).to eq true
        expect(bindings[i].inbound_column).to be_a InboundData::Column
        expect(bindings[i].inbound_column.lookup_list).to be_a Array
        expect(bindings[i].inbound_column.lookup_list.size).to eq 1
        expect(bindings[i].inbound_column.lookup_list[0]).to be_a  InboundData::LookupSupport
        expect(bindings[i].inbound_column.lookups.first).to be_a  InboundData::LookupSupport
        expect(bindings[i].inbound_column.lookups.first).to eq bindings[i].inbound_column.lookup_list[0]
      end
    end

    it "should parse header for where clause field" do

      # Owner has a name and belongs_to Project which has a title i.e lookup on title
      headers = [ "project:title", "Project:title"]

      bindings = method_mapper.map_inbound_headers( Owner, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |c, i|
        first_lookup = bindings[i].inbound_column.lookups.first
        expect(first_lookup.klass).to eq Project
        expect(first_lookup.field).to eq 'title'
        expect(first_lookup.where_value).to eq nil
      end
    end

    it "should parse header for where clause field & value belongs_to" do

      # Owner has a name and belongs_to Project
      headers = [ 'project:title:my first project', 'Project:title:my first project']

      bindings = method_mapper.map_inbound_headers( Owner, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |c, i|
        first_lookup = bindings[i].inbound_column.lookups.first
        expect(first_lookup.klass).to eq Project
        expect(first_lookup.field).to eq 'title'
        expect(first_lookup.where_value).to eq 'my first project'
      end
    end

    it "should parse header for where clause field & value has_one" do

      # class Version < ActiveRecord::Base has_many :releases
      # has_one :long_and_complex_table_linked_to_version
      headers = [ 'long_and_complex_table_linked_to_version:price:10.2', 'Long_And Complex Table_linked_to_version:price:10.2']

      bindings = method_mapper.map_inbound_headers( Version, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |c, i|
        first_lookup = bindings[i].inbound_column.lookups.first
        expect(first_lookup.klass).to eq LongAndComplexTableLinkedToVersion
        expect(first_lookup.field).to eq 'price'
        expect(first_lookup.where_value).to eq '10.2'
      end
    end

    it "should parse header for where clause field & value & global data has_many" do

      # Owner  has_many :digitals which has field attachment_file_name
      headers = [ 'digitals:attachment_file_name:my pdf:random data for a loader',
                  'Digitals:attachment_file_name:my pdf:random data for a loader']

      bindings = method_mapper.map_inbound_headers( Owner, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |c, i|
        first_lookup = bindings[i].inbound_column.lookups.first
        expect(first_lookup.klass).to eq Digital
        expect(first_lookup.field).to eq 'attachment_file_name'
        expect(first_lookup.where_value).to eq 'my pdf'
        expect(bindings[i].inbound_column.data).to be_a Array
        expect(bindings[i].inbound_column.data).to include 'random data for a loader'
      end
    end

    it "should raise an error when association has no such field" do

      # Owner  has_many :digitals which has field attachment_file_name
      headers = [ 'digitals:blah_blah',
                  'Digitals:nonsense:with a value',
                  'Digitals:nonsense:with a value:and random data']

      expect { method_mapper.map_inbound_headers( Owner, headers ) }.to raise_error NoSuchOperator
    end



    it "should enable us to sort bindings into arbitrary processing order" do

      headers = [ "Value as string", :value_as_string, "value_as boolean", 'Value_As_Double']

      operators = %w{ value_as_string value_as_string value_as_boolean value_as_double }

      bindings = method_mapper.map_inbound_headers( Project, headers )

      pending 'sorting methods'

      bindings.sort

    end

  end

end