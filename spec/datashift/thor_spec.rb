# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
#
# License::   MIT - Free, OpenSource
#
# Details::   Specification for Thor tasks supplied with datashift
#
#             Test are often within a call to
#                 run_in(rails_sandbox_path)
#             so we can access real model data from the dummy app
#
require 'thor'
require 'thor/group'
require 'thor/runner'

require_relative '../spec_helper'

module DataShift

  describe 'Thor high level command line tasks' do

    context 'Loading commands' do

      before(:all) do
        DataShift.load_commands
      end

      it 'should list available datashift thor tasks' do
        x = run_in(rails_sandbox_path) do
          capture_stream(:stdout){ require 'datashift' ; Thor::Runner.start(["list"]) }
        end

        expect(x).to start_with("datashift\n--------")

        expect(x).to include "csv"
        expect(x).to include "excel"
        expect(x).to include "csv"
      end

      it "tasks have been instantiated" do
        expect(Datashift::Generate.new).to be
        expect(Datashift::Config.constants.include?(:Generate)).to be_truthy
        expect(Datashift::Config::Generate.new).to be
        expect(Datashift::Export.new).to be
        expect(Datashift.constants.include?(:Import)).to be
        expect(Datashift::Generate.new).to be
        expect(Datashift::Paperclip.new).to be
      end

    end

    context 'Import CLI' do

      before(:all) do
        DataShift.load_commands
      end

      before(:each) do
        results_clear
      end

      it 'should generate skeleton import config for a model' do
        expected = File.join(results_path, 'thor_spec_project_config.yaml')

        expect(File.exists?(expected)).to eq false

        #t datashift:config:import -m Spree::Variant -r /tmp

        run_in(rails_sandbox_path) do
          options = ['--model', 'Project', '--result', File.join(results_path, 'thor_spec_project_config.yaml')]

          output = capture_stream(:stdout) { Datashift::Config::Generate.new.invoke(:import, [], options) }

          puts output
          expect(File.exists?(expected)).to eq true
          expect(output).to include('Creating new configuration file')
        end
      end

      it 'should provide tasks to import data from a CSV file', duff: true do

        pending "Seems to be no way to set class options for invoke"
        # datashift:generate:config:import -m Spree::Product -p ~/blah.yaml

        cmd = ['--model', 'Project', '--result', results_path.to_s]

        #options = { 'model' => 'Project', 'input' => results_path.to_s}

        output = capture_stream(:stdout) {
        # byebug
         #Datashift::Import.class_options(options)
         Datashift::Import.new.invoke(:csv, [], cmd)
        }
      end
    end

    context 'Generate CLI' do
      before(:each) do
        results_clear
      end
      it 'should list available datashift thor tasks' do
        x = run_in(rails_sandbox_path) do
          capture_stream(:stdout){ require 'datashift' ; Thor::Runner.start(["list"]) }
        end

        expect(x).to start_with("datashift\n--------")

        expect(x).to include "csv"
        expect(x).to include "excel"
        expect(x).to include "csv"
      end

      it "tasks have been instantiated" do
        expect(Datashift.constants.include?(:Import)).to be
        expect(Datashift::Export.new).to be
        expect(Datashift::Import.new).to be
        expect(Datashift::Generate.new).to be
        expect(Datashift::Paperclip.new).to be
      end

    end

    context 'Export CLI' do

      let(:number_of_projects) { 7 }

      before(:all) do
        DataShift.load_commands
      end

      before(:each) do
        clear_everything

        create_list(:project, number_of_projects)

        create( :project_with_user ) # creates a Project with associations
      end

      it 'should run datashift:export:csv to export a model to CSV file' do
        expected =  result_file 'rspec_thor_project_export.csv'

        args = ['--model', 'Project', '--result', expected, '--associations']

        current = Project.count

        expect(current).to be  > 7

        run_in(rails_sandbox_path) do

          capture_stream(:stdout) { Datashift::Export.new.invoke(:csv, [], args) }

          expect(File.exist?(expected)).to eq true

          File.foreach(expected) {}
          count = $INPUT_LINE_NUMBER
          expect(count).to eq current + 1     # +1 for the header row
        end
      end

      it 'should run datashift:export:csv to export a model to a EXCEL file' do
        expected =  result_file 'rspec_thor_project_export.xls'

        args = ['--model', 'Project', '--result', expected, '--associations']

        run_in(rails_sandbox_path) do

          capture_stream(:stdout) { Datashift::Export.new.invoke(:excel, [], args) }

          expect(File.exist?(expected)).to eq true

          excel = DataShift::Excel.new
          excel.open(expected)

          expected_rows = Project.count + 1
          last_idx = Project.count

          expect(excel.num_rows).to eq expected_rows

          user_column_index = excel.row(0).index 'user'
          owner_column_index = excel.row(0).index 'owner'

          expect(user_column_index).to be > -1

          # Factories should have built the project WITHOUT associated owner data first
          expect( excel[1, owner_column_index] ).to be_nil
          expect( excel[1, user_column_index] ).to_not be_nil

          # Factories should have built the project WITH real associated user data last
          expect( excel[last_idx, user_column_index] ).to include 'mr'

          owner_idx = excel.row(0).index 'owner'

          expect(owner_idx).to be > -1

          expect( excel[last_idx, owner_idx] ).to include '10000.23'
        end
      end

      it 'should run datashift:export:db to export whole DB to EXCEL' do

        # Writes one file per model into a PATH
        expected_path =  results_path

        args = ['--path', expected_path, '--associations']

        run_in(rails_sandbox_path) do

          output = capture_stream(:stdout) { Datashift::Export.new.invoke(:db, [], args) }

          ['users', 'projects', 'milestones', 'owners', 'categories', 'versions', 'loader_releases',
           'long_and_complex_table_linked_to_versions', 'empties', 'digitals', 'categories'].each do |f|

            expected = File.join(expected_path, "#{f}.xls")
            expect(File.exist?(expected) ).to be_truthy, "MissingFile\nExport file [#{expected}] not found"
          end

          excel = Excel.new
          excel.open(  expected = File.join(expected_path, "projects.xls") )

          expected_rows = Project.count + 1
          last_idx = Project.count

          expect(excel.num_rows).to eq expected_rows

          user_column_index = excel.row(0).index 'user'
          owner_column_index = excel.row(0).index 'owner'

          expect(user_column_index).to be > -1

          # Factories should have built the project WITHOUT associated owner data first
          expect( excel[1, owner_column_index] ).to be_nil
          expect( excel[1, user_column_index] ).to_not be_nil

          # Factories should have built the project WITH real associated user data last
          expect( excel[last_idx, user_column_index] ).to include 'mr'

          expect(owner_column_index).to be > -1
          expect( excel[last_idx, owner_column_index] ).to include '10000.23'
        end
      end

    end # end Export CLi

    context 'Import CLI' do

      before(:all) do
        DataShift.load_commands
      end

      before(:each) do
        clear_everything
      end

      it 'should run datashift:import:csv to import data from a CSV file' do

        input_file = ifixture_file('csv/SimpleProjects.csv')

        options = ['--model', 'Project', '--input', input_file]

        run_in(rails_sandbox_path) do
          count = Project.count

          output = capture_stream(:stdout) { Datashift::Import.new.invoke(:csv, [], options) }

          # TODO for now hard code 3  - should probably count the lines in the file
          expect(Project.count - count).to eq 3

          expect(output).to include('Processing Summary Report')
          expect(output).to include('There were NO failures')
        end

      end

      it 'should run datashift:import:excel to import data from Excel spreadsheet' do

        input_file = ifixture_file('SimpleProjects.xls')

        options = ['--model', 'Project', '--input', input_file]

        run_in(rails_sandbox_path) do
          count = Project.count

          output = capture_stream(:stdout) { Datashift::Import.new.invoke(:excel, [], options) }

          # TODO for now hard code 3  - should probably count the lines in the file
          expect(Project.count - count).to eq 3

          expect(output).to include('Processing Summary Report')
          expect(output).to include('There were NO failures')
        end

      end

    end

    context 'Generate CLI' do
      before(:each) do
        results_clear
      end

      it 'should provide tasks to generate a mapping doc' do

        # Access real model in dummy
        run_in(rails_sandbox_path) do
          cmd = ['--model', 'Project', '--result', File.join(results_path, 'thor_spec_gen_project.csv')]

          output = capture_stream(:stdout) { Datashift::Generate.new.invoke(:csv, [], cmd) }

          puts output
          expect(File.exists?(File.join(results_path, 'thor_spec_gen_project.csv'))).to eq true
          expect(output).to include('Datashift: CSV Template COMPLETED')
        end

      end
    end

    # thor datashift:export:csv -m, --model=MODEL -r, --result=RESULT              ...
    # thor datashift:export:excel -m, --model=MODEL -r, --result=RESULT            ...
    # thor datashift:generate:excel -m, --model=MODEL -r, --result=RESULT          ...
    # thor datashift:import:csv -i, --input=INPUT -m, --model=MODEL                ...
    # thor datashift:import:excel -i, --input=INPUT -m, --model=MODEL              ...
    # thor datashift:paperclip:attach -a, --attachment-klass=ATTACHMENT_KLASS -f, -...                                     ...
    # thor datashift:tools:zip -p, --path=PATH -r, --results=RESULTS               ...


    # N.B Tasks that fire up Rails application need to be run in own Thread or else get
    #  ...  You cannot have more than one Rails::Application

    it 'should be able to import a model from a complex excel through import CLI' do
      skip 'How to run once rails already initialzed .. error : database configuration does not specify adapter'

      x = Thread.new {
        run_in(Sandbox.rails_sandbox_path) do
          stdout = capture_stream(:stdout){
            Thor::Runner.start(['datashift:import:excel', '-m', 'Project', '-i', ifixture_file('ProjectsSingleCategories.xls')])
          }
          puts stdout
        end
      }
      x.join
    end

    it 'should attach Images to a specified Class from a directory' do
      skip 'better understanding of testign thor'

      # Owner has_many :digitals of type Digital

      # Owner has a name by which we can id/look it up

      args = [
        '--attachment-klass',        'Digital',
        '--attach-to-klass',         'Owner',
        '--attach-to-find-by-field', 'name',
        '--attach-to-field',         'digitals']

      # which boils down to
      #
      # Digital.find_by_name( abc ).digitals << :Digital.new( File.read('abc_001.jpg') )

      args << '--input' << File.join(fixtures_path, 'images')

      puts "Running attach with: #{args}"

      x = capture_stream(:stdout) { Thor::Runner.start(['datashift:paperclip:attach', [], args]) }

      expect(x).to include "datashift\n--------"
      # x.should =~ / csv -i/
      # x.should =~ / excel -i/
    end
  end
end