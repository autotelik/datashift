# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Feb 2015
# License::   MIT
#
# Details::   Specs for Mapping aspects
#             Provides automatic mapping between different system's column headings
#
require File.join(File.dirname(__FILE__), 'spec_helper')


module DataShift

  describe 'Mapping Generator' do

    include_context "ClearAllCatalogues"

    before(:each) do
      results_clear
    end

    context 'generation' do

      # maybe more trouble than its worth - more investigation needed

      #include FakeFS::SpecHelpers::Rails     # careful where this goes, restrict it's scope to specific contexts
      #FakeFS.activate!
      #FakeFS::FileSystem.clone(File.join(DataShift::root_path, 'spec'))

      let(:map_file) { result_file("mapper.yaml") }

      let(:mapping_generator) {MappingGenerator.new }

      context 'basic templates without a class' do

        it "should generate a standard default mapping" do
          result = mapping_generator.generate

          expect(result).to be_a String
          expect(result).to include 'source_column_heading_0:'
          expect(result).to include 'dest_column_heading_0'
        end

        it "should have a consistent starting title" do
          result = mapping_generator.generate

          expect(result).to include MappingGenerator.title
        end

        it "should generate a standard default mapping file" do
          mapping_generator.generate(nil, {:file => map_file} )

          expect(File.exist?(map_file)).to be true
        end

        it "should generate a mapping doc with pre supplied title" do

          result = mapping_generator.generate(nil,  {:file => map_file, title: 'rspec_mappings:'} )

          expect(File.exist?(map_file)).to be true

          # TODO file matchers like
          # expect(map_file).have_content(/ blah /)
          expect( File.read(map_file) ).to include "rspec_mappings:"
        end

      end

      context 'real mappings' do

        let(:map_file) { result_file("project_mapper.yaml") }

        it "should generate a populated mapping doc for a class" do
          result = mapping_generator.generate( Project,  {:file => map_file} )

          expect(File.exist?(map_file)).to be true
          expect( File.read(map_file) ).to include "Project:"
        end

        it "should be able to extract headers from_excel", :fail => true  do
          mapping_generator.generate_from_excel(ifixture_file('SimpleProjects.xls'), :file => map_file )

          expect(mapping_generator.headers.empty?).to eq false
          expect(mapping_generator.headers.class).to eq  Headers
        end


        it "should be able to extract headers from_excel" do

          mapping_generator.generate_from_excel(ifixture_file('SimpleProjects.xls'), :file => map_file )

          # bit flakey need to manually st expected spreadsheet values
          # value_as_string,	Value as Text,	value as datetime,	value_as_boolean,	value_as_double

          expect(mapping_generator.headers.size).to eq 5
          expect(mapping_generator.headers[0]).to eq 'value_as_string'
          expect(mapping_generator.headers[4]).to eq 'value_as_double'
        end


        it "should be able to generate a mapping from_excel"  do

          mapping_generator.generate_from_excel(ifixture_file('SimpleProjects.xls'), :file => map_file )

          expect(File.exist?(map_file)).to be true

        end
      end

    end

  end
end