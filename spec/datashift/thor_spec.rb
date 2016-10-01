# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
#
# License::   MIT - Free, OpenSource
#
# Details::   Specification for Thor tasks supplied with datashift
#
require 'thor'
require 'thor/group'
require 'thor/runner'

require File.dirname(__FILE__) + '/../spec_helper'

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

        puts x
        expect(x).to start_with("datashift\n--------")

        expect(x).to include "csv"
        expect(x).to include "excel"
        expect(x).to include "csv"
      end

      it "tasks have been instantiated" do
        expect(Datashift::Generate.new).to be
        expect(Datashift::Config.new).to be
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

      it 'should provide tasks to generate a mapping doc', duff: true do
        # datashift:generate:config:import -m Spree::Product -p ~/blah.yaml

        # cmd = ['--model', 'Project', '--result', results_path.to_s]

        cmd = { 'model' => 'Project', 'input' => results_path.to_s}

        #output = capture_stream(:stdout) {
        # byebug
        # Datashift::Import.class_options(cmd)
        # Datashift::Import.invoke(:csv, cmd, cmd)
        #}
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