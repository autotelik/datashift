# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Feb 2015
# License::   MIT
#
# Details::   Specs for Mapping aspects
#             Provides automatic mapping between different system's column headings
#
require File.join(File.dirname(__FILE__), 'spec_helper')

require 'mapping_generator'

describe 'Mapping Services' do

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

    let(:mapper) {  DataShift::MappingGenerator.new(map_file) }

    it "should generate a standard default mapping" do
      result = mapper.generate

      expect(result).to be_a String
      expect(result).to include 'source_column_heading_0:'
    end

    it "should have a consistent starting title" do
      result = mapper.generate

      expect(result).to include DataShift::MappingGenerator.title
    end

    it "should generate a standard default mapping file" do
      mapper.generate(nil, {:file => map_file} )

      expect(File.exists?(map_file)).to be true
    end

    it "should generate a mapping doc with pre supplied title" do

      mapper.generate(nil,  {:file => map_file, title: 'rspec_mappings'} )

      expect(File.exists?(map_file)).to be true

      # TODO file matchers like
      # expect(map_file).have_content(/ blah /)
      expect( File.read(map_file) ).to include "rspec_mappings"
    end


    it "should generate a populated mapping doc for a class" do
      mapper.generate( Project,  {:file => map_file} )

      expect(File.exists?(map_file)).to be true
      expect( File.read(map_file) ).to include "Project:"
    end


    it "should be able to generate a mapping from_excel" do

      mapper.generate_from_excel(ifixture_file('SimpleProjects.xls'), :file => map_file )

      expect(File.exists?(map_file)).to be true

    end

    it "should be able to create a mapping service for a class" do
      mapping_services = DataShift::MappingService.new(Project)

      expect(mapping_services).to be
    end

  end

  context 'CLI' do

    before(:each) do
      load File.join( rspec_datashift_root,'lib/thor/mapping.thor')

      results_clear
    end

    it "should provide tasks to generate a mapping doc" do

      opts  = {:model =>  "Project", :result => "#{results_path}"}

      run_in(rails_sandbox()) do
        output = capture(:stdout) { Datashift::Mapping.new.invoke(:template, [], opts) }

        puts output

        expect(output).to include("Output generated")
      end
    end


  end

  context 'reading' do

    it "should be able to read a mapping" do

      f = result_file("mapping_service_project.yaml")

      mapper = DataShift::MappingGenerator.new(f)

      mapper.generate(Project, {:file => f} )

      expect(File.exists?(f)).to be true

      mapping_service = DataShift::MappingService.new(Project)

      mapping_service.read(f)

      expect(mapping_service.map_file_name).to eq f

      expect(mapping_service.raw_data).to_not be_empty
      expect(mapping_service.yaml_data).to_not be_empty

      expect(mapping_service.mapping_entry).to be_a OpenStruct

      # puts mapping_service.mapping_entry.inspect
      expect(mapping_service.mapping_entry.mappings).to be_a Hash
      expect(mapping_service.mapping_entry['mappings']).to be_a Hash

    end

    it "should be able to use a mapping" do

      f = result_file("mapping_service_project.yaml")

      mapper = DataShift::MappingGenerator.new(f)

      mapper.generate(Project, {:file => f} )

      expect(File.exists?(f)).to be true

      mapping_service = DataShift::MappingService.new(Project)

      mapping_service.read(f)

      expect(mapping_service.map_file_name).to eq f

      expect(mapping_service.raw_data).to_not be_empty
      expect(mapping_service.yaml_data).to_not be_empty

      expect(mapping_service.mapping_entry).to be_a OpenStruct

      # puts mapping_service.mapping_entry.inspect
      expect(mapping_service.mapping_entry.mappings).to be_a Hash
      expect(mapping_service.mapping_entry['mappings']).to be_a Hash

    end

  end

end