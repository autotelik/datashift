# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Aug 2015
# License::   MIT
#
# Details::   Specs for Mapping aspects
#             Provides automatic mapping between different system's column headings
#
require File.join(File.dirname(__FILE__), 'spec_helper')

require 'mapping_generator'

describe 'Mapping Services' do

  before(:all) do
    DataShift::MethodDictionary.clear
    DataShift::MethodDictionary.find_operators( Project )
  end

  before(:each) do
    load File.join( rspec_datashift_root,'lib/thor/mapping.thor')
  end


  it "should generate an empty mapping doc" do

    f = result_file("mapper.yaml")

    mapper = DataShift::MappingGenerator.new(f)

    mapper.generate()

    expect(File.exists?(f)).to be true
  end


  it "should generate a mapping doc with pre supplied title" do

    f = result_file("mapper.yaml")

    mapper = DataShift::MappingGenerator.new(f)

    mapper.generate(nil, {:name => "MyDataShiftMappings"} )

    expect(File.exists?(f)).to be true
  end

  it "should generate a populated mapping doc for a class" do

    f = result_file("mapper_project.yaml")

    mapper = DataShift::MappingGenerator.new(f)

    mapper.generate( Project )

    expect(File.exists?(f)).to be true
  end

  it "should be able to create a mapping service for a class" do
    mapping_services = DataShift::MappingService.new(Project)

    expect(mapping_services).to be
  end

  it "should be able to read a mapping" do

    f = result_file("mapping_service_project.yaml")

    mapper = DataShift::MappingGenerator.new(f)

    mapper.generate(Project, {:name => "ProjectMappings"} )

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

  it "should be able to generate a mapping from_excel" do

    f = result_file("mapping_service_excel.yaml")

    mapper = DataShift::MappingGenerator.new(f)

    mapper.generate_from_excel(ifixture_file('SimpleProjects.xls') )

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