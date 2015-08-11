# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
require File.join(File.dirname(__FILE__), '/../spec_helper')

module DataShift

  module InboundData

    describe 'Inbound Data' do
      it 'should store details of inbound lookup' do
        ls = LookupSupport.new( Project, :title, 'my title')
        expect(ls).to be
      end

      it 'should store details of inbound column' do
        c = Column.new( 'Value As A String')
        expect(c).to be
      end

      it 'should store details of inbound column with its column number' do
        c = Column.new( 'Value As A String', 0)
        expect(c).to be
      end

      context 'lookups' do
        let(:create_project) { create(:project, title: 'my title') }

        let(:lookup) { LookupSupport.new( Project, :title, 'my title') }

        it 'should enable lookup of a domain object' do
          create_project
          result = lookup.klass.where( lookup.field => lookup.where_value ).first
          expect(result).to be_a Project
        end

        it 'should provide shortcut to return active record relation', fail: true do
          id = create_project.id
          result = lookup.find
          expect(result).to be_a ActiveRecord::Relation
          expect(result.first.id).to eq id
        end
      end
    end
  end
end
