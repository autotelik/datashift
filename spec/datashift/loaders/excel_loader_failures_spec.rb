# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
#
require_relative '../../spec_helper'

module  DataShift

  describe 'Excel Loader Failures' do
    include_context 'ClearAllCatalogues'

    let(:loader) { ExcelLoader.new }

    let(:expected) { ifixture_file('SimpleProjects.xls') }

    before(:each) do
      create_list(:category, 5)
    end

    context 'progress monitor' do
      it 'should process excel spreadsheet with extra undefined columns', duff: true do
        expected = ifixture_file('BadAssociationName.xls')

        loader.run(expected, Project)

        puts loader.loaded_count
        puts loader.failed_count

      end
    end

    context 'reporters' do

      it 'should be able to perform reporting' do
        expect(loader.respond_to? :report).to eq true
      end

      it 'can access list of reporters' do
        expect(loader.reporters).to be_a Array
      end


      class MyReporter < DataShift::Reporters::Reporter
        def report
          "Rspec expects this text"
        end
      end

      let(:reporter) { MyReporter.new }

      it 'can configure list of reporters' do
        loader.reporters = [reporter]

        expect(loader.reporters).to eq [reporter]
      end

      it 'can use a self configured list of reporters' do
        loader.reporters = [reporter]

        expect(loader.reporters.first.report).to eq "Rspec expects this text"
      end

    end

  end
end
