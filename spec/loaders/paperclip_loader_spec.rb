# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
#
require File.dirname(__FILE__) + '/../spec_helper'

require 'paperclip/attachment_loader'

Paperclip.options[:command_path] = '/usr/local/bin/'

describe 'PaperClip Bulk Loader' do
  include DataShift::Logging

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

  it 'should create a new paperclip loader to load a directory of attachments' do
    loader = DataShift::Paperclip::AttachmentLoader.new(path, common_options)
    expect(loader.file_name).to eq path
    expect(loader.attach_to_klass).to be_nil
    expect(loader.attach_to_find_by_field).to be_nil
    expect(loader.attach_to_field).to be_nil
  end

  it 'should create loader and define class to attach to' do
    loader = DataShift::Paperclip::AttachmentLoader.new(path, attachment_options.merge(common_options))

    expect(loader.attach_to_klass).to eq Owner
    expect(loader.attach_to_find_by_field).to  eq :name
    expect(loader.attach_to_field).to eq :digitals
  end

  context("Loading attachments") do

    let(:owner_names) { %w(DEMO_001 DEMO_002 DEMO_003 DEMO_004) }

    before(:each) do
      # these names should be included in the attachment file name somewhere
      owner_names.each do |n|
        Owner.create( name: n )
      end
    end

    it 'should bulk load from a directory file system' do

      loader = DataShift::Paperclip::AttachmentLoader.new(path, attachment_options.merge(common_options))

      loader.run(Digital, split_file_name_on: '_')

      puts Owner.all.collect(&:digitals).inspect

    end

    it 'should handle not being able to find matching record' do

      opts = { attach_to_klass: Owner, attach_to_find_by_field: :name }.merge(common_options)

      loader = DataShift::Paperclip::AttachmentLoader.new(path, opts)

      loader.run(Digital, split_file_name_on: '_')

      expect(Dir.glob('MissingAttachmentRecords/*.jpeg', File::FNM_CASEFOLD).size).to eq owner_names.size
    end
  end

end
