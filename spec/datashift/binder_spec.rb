# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::   Specs for Binder aspect of Active Record Loader
#             Binder provides the bridge between 'strings' e.g column headings
#             and a classes different types of assignment operators/associations
#
require File.join(File.dirname(__FILE__), '/../spec_helper')

module DataShift

  describe Binder do
    include_context 'ClearThenManageProject'

    let(:binder) { Binder.new }

    context 'errors binding headers' do
      let(:headers) {
        [:value_as_string, :owner, :bad_no_such_column, :value_as_boolean, :value_as_double, :more_rubbish_as_nil]
      }

      before(:each) do
        binder.map_inbound_headers( Project, headers )
      end

      let(:bindings) { binder.bindings }

      it 'uses NoMethodBinding object methods when no such operator' do
        expect(bindings.size).to eq 6

        expect(bindings[2]).to be_a NoMethodBinding
        expect(bindings[5]).to be_a NoMethodBinding

        expect(bindings[0]).to be_a MethodBinding
      end

      it 'should populate missing_bindings  when no such operator', duff: true do
        expect(binder.missing_bindings.size).to eq 2
      end

      it 'should indicate when bindings  missing' do
        expect(binder.missing_bindings?).to eq true
      end

      it 'should indicate names of missing bindings' do
        missing = binder.headers_missing_bindings

        expect(missing.size).to eq 2

        expect(missing[0]).to eq 'bad_no_such_column'
        expect(missing[1]).to eq 'more_rubbish_as_nil'
      end

      it 'should indicate index of missing bindings ' do
        missing = binder.indexes_missing_bindings

        expect(missing[0]).to eq 2
        expect(missing[1]).to eq 5
      end

    end

    context 'errors binding headers with lookup data' do

      it 'uses NoMethodBinding object methods when operator has no such lookup field' do
        # Owner  has_many :digitals which has field attachment_file_name
        headers = ['digitals:attachment_file_name',
                   'Digitals:nonsense_lookup_field',
                   'Digitals:nonsense:with a value',
                   'Digitals:nonsense:with a value:and random data']

        binder.map_inbound_headers(Owner, headers)

        expect(binder.bindings.size).to eq 4
        expect(binder.missing_bindings.size).to eq 3

        expect(binder.missing_bindings?).to eq true
        expect(binder.missing_bindings[0].reason).to include 'Field [nonsense_lookup_field] Not Found'
      end
    end

    context 'errors binding headers' do

    end
    let (:headers) { [:value_as_string, :owner, :value_as_boolean, :value_as_double] }

    it 'should find a set of methods based on a list of column symbols' do
      bindings = binder.map_inbound_headers( Project, headers )
      expect(bindings.size).to eq 4
    end

    it 'should map a list of column names to a set of method details' do
      headers = %w(value_as_double value_as_string bad_no_such_column value_as_boolean)

      bindings = binder.map_inbound_headers( Project, headers )

      expect(bindings.size).to eq 4

      expect(bindings[2]).to be_a NoMethodBinding

      expect(bindings[0]).to be_a MethodBinding
      expect(bindings.last).to be_a MethodBinding
    end

    it 'should populate a method binding instance based on column and database info' do
      headers = [:value_as_string, :owner, :value_as_boolean, :value_as_double]

      bindings = binder.map_inbound_headers( Project, headers )

      expect(bindings.size).to eq 4

      expect(bindings[0]).to be_a MethodBinding

      headers.each_with_index do |_c, i|
        expect(bindings[i].index).to eq i
        expect(bindings[i].inbound_column.index).to eq i
      end
    end

    it 'should map between user name and domain model attribute' do
      headers = ['Value as string', :value_as_string, 'value_as boolean', 'Value_As_Double']

      operators = %w(value_as_string value_as_string value_as_boolean value_as_double)

      bindings = binder.map_inbound_headers( Project, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |c, i|
        expect(bindings[i].valid?).to eq true
        expect(bindings[i].index).to eq i
        expect(bindings[i].source).to eq c.to_s
        expect(bindings[i].operator).to eq operators[i]
      end
    end

    it 'should map between user name and domain model has_one association' do
      # Project has_one  :owner
      headers = ['owner', 'Owner', :owner]

      operators = %w(owner owner owner)

      bindings = binder.map_inbound_headers( Project, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |c, i|
        expect(bindings[i].valid?).to eq true
        expect(bindings[i].index).to eq i
        expect(bindings[i].source).to eq c.to_s
        expect(bindings[i].operator).to eq operators[i]
      end
    end

    it 'should map between user name and domain model has_many association' do
      # Project has_many :loader_releases
      headers = ['loader_releases', 'Loader Releases', :loader_releases]

      operators = %w(loader_releases loader_releases loader_releases)

      bindings = binder.map_inbound_headers( Project, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |c, i|
        expect(bindings[i].valid?).to eq true
        expect(bindings[i].index).to eq i
        expect(bindings[i].source).to eq c.to_s
        expect(bindings[i].operator).to eq operators[i]
      end
    end

    it 'should parse header for where  fields and make available through inbound_column' do
      # Owner has a name and belongs_to Project which has a title i.e lookup on title
      headers = ['project:title']

      bindings = binder.map_inbound_headers( Owner, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |_c, i|
        expect(bindings[i].valid?).to eq true
        expect(bindings[i].inbound_column).to be_a InboundData::Column
        expect(bindings[i].inbound_column.lookup_list).to be_a Array
        expect(bindings[i].inbound_column.lookup_list.size).to eq 1
        expect(bindings[i].inbound_column.lookup_list[0]).to be_a InboundData::LookupSupport
        expect(bindings[i].inbound_column.lookups.first).to be_a InboundData::LookupSupport
        expect(bindings[i].inbound_column.lookups.first).to eq bindings[i].inbound_column.lookup_list[0]
      end
    end

    it 'should parse header for where clause field' do
      # Owner has a name and belongs_to Project which has a title i.e lookup on title
      headers = ['project:title', 'Project:title']

      bindings = binder.map_inbound_headers( Owner, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |_c, i|
        first_lookup = bindings[i].inbound_column.lookups.first
        expect(first_lookup.klass).to eq Project
        expect(first_lookup.field).to eq 'title'
        expect(first_lookup.where_value).to eq nil
      end
    end

    it 'should parse header for where clause field & value belongs_to' do
      # Owner has a name and belongs_to Project
      headers = ['project:title:my first project', 'Project:title:my first project']

      bindings = binder.map_inbound_headers( Owner, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |_c, i|
        first_lookup = bindings[i].inbound_column.lookups.first
        expect(first_lookup.klass).to eq Project
        expect(first_lookup.field).to eq 'title'
        expect(first_lookup.where_value).to eq 'my first project'
      end
    end

    it 'should parse header for where clause field & value has_one' do
      # class Version < ActiveRecord::Base has_many :releases
      # has_one :long_and_complex_table_linked_to_version
      headers = ['long_and_complex_table_linked_to_version:price:10.2', 'Long_And Complex Table_linked_to_version:price:10.2']

      bindings = binder.map_inbound_headers( Version, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |_c, i|
        first_lookup = bindings[i].inbound_column.lookups.first
        expect(first_lookup.klass).to eq LongAndComplexTableLinkedToVersion
        expect(first_lookup.field).to eq 'price'
        expect(first_lookup.where_value).to eq '10.2'
      end
    end

    it 'should parse header for where clause field & value & global data has_many' do
      # Owner  has_many :digitals which has field attachment_file_name
      headers = ['digitals:attachment_file_name:my pdf:random data for a loader',
                 'Digitals:attachment_file_name:my pdf:random data for a loader']

      bindings = binder.map_inbound_headers( Owner, headers )

      expect(bindings.size).to eq headers.size

      headers.each_with_index do |_c, i|
        first_lookup = bindings[i].inbound_column.lookups.first
        expect(first_lookup.klass).to eq Digital
        expect(first_lookup.field).to eq 'attachment_file_name'
        expect(first_lookup.where_value).to eq 'my pdf'
        expect(bindings[i].inbound_column.data).to be_a Array
        expect(bindings[i].inbound_column.data).to include 'random data for a loader'
      end
    end

    it 'should enable us to sort bindings into arbitrary processing order' do
      headers = ['Value as string', :value_as_string, 'value_as boolean', 'Value_As_Double']

      operators = %w(value_as_string value_as_string value_as_boolean value_as_double)

      bindings = binder.map_inbound_headers( Project, headers )

      pending 'sorting methods'

      bindings.sort
    end
  end

end
