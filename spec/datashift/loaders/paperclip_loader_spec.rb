# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
#
require_relative '../../spec_helper'

require 'paperclip/attachment_loader'

Paperclip.options[:command_path] = '/usr/local/bin/'

describe 'PaperClip Bulk Loader' do
  include DataShift::Logging

  before(:each) do
    DataShift::Transformation::Factory.reset
  end

  module Paperclip
    module Interpolations

      # Returns the Rails.root constant.
      def rails_root(_attachment, _style_name)
        '.'
      end
    end
  end

  let(:path) { File.join(fixtures_path, 'images') }

  let(:common_options) { { verbose: true } }

  # Owner.where(:name = 'jeff mills').first.digitals << DigitalAttachmentLoadedFromPath
  let(:attachment_options) do
    {
      attach_to_klass: Owner,
      attach_to_find_by_field: :name,
      attach_to_field: :digitals
    }
  end

  let(:paper_clip_attachment_class) { Digital }

  let(:loader) { DataShift::Paperclip::AttachmentLoader.new }

  it 'should create a new paperclip loader to load a directory of attachments' do
    expect(loader).to be
    expect(loader.attach_to_klass).to be_nil
    expect(loader.attach_to_find_by_field).to be_nil
    expect(loader.attach_to_field).to be_nil
  end

  it 'can be configured via Hash to load attachments against class found via field name, attached to another field' do
    loader.init_from_options(attachment_options)
    expect(loader.attach_to_klass).to eq attachment_options[:attach_to_klass]
    expect(loader.attach_to_find_by_field).to eq attachment_options[:attach_to_find_by_field]
    expect(loader.attach_to_field).to eq attachment_options[:attach_to_field]
  end

  it 'can be configured to load attachments against class as a String' do
    attachment_options[:attach_to_klass] = 'Owner'
    loader.init_from_options(attachment_options)
    expect(loader.attach_to_klass).to eq  Owner
  end

  it 'can be initialised directly with owning class, found via field name, attached to another field' do
    loader.init(Owner, :image, :digitals)
    expect(loader.attach_to_klass).to eq Owner
    expect(loader.attach_to_find_by_field).to eq :image
    expect(loader.attach_to_field).to eq :digitals
  end

  context('Loading attachments') do

    let(:owner_names) { %w(DEMO_001 DEMO_002 DEMO_003 DEMO_004) }

    before(:each) do
      # these Owner names should be embedded in the attachment FILE NAME somewhere
      owner_names.each do |n|
        create( :owner, name: n )
      end

      expect(Owner.count).to eq 4

      loader.init_from_options attachment_options
    end

    it 'should bulk load from a directory file system', duff: true do

      expect(Owner.count).to eq 4

      loader.split_file_name_on = '_'

      loader.run(path, Digital)

      expect(Owner.first.digitals.size).to be > 0
    end

    it 'should save failed images to folder when unable to find matching record' do

      # use a non existent field to cause error
      loader.attach_to_find_by_field = :junk
      loader.split_file_name_on = '_'

      loader.run(path, Digital)

      expect(Dir.glob('MissingAttachmentRecords/*.jpeg', File::FNM_CASEFOLD).size).to eq owner_names.size
    end
  end

end
