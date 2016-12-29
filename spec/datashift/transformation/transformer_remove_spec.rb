# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Specs around Transforming inbound data
#
require File.join(File.dirname(__FILE__), '/../../spec_helper')

module  DataShift

  describe 'Transformation Remove' do
    include_context 'ClearThenManageProject'

    context 'Column removals' do
      it 'should process options to remove unwanted columns' do
        headers = [:a, :b, :c, :d, :e, :f]

        DataShift::Configuration.configure do |config|
          config.remove_columns = [:b, :f]
        end

        DataShift::Transformation::Remove.new.unwanted_columns(headers )

        expect(headers).to_not include [:b, :f]
      end

      it 'should process options to remove unwant5ed columns' do
        headers = [:a, :id, :c, :d, :e, :created_on, :f, :updated_on]

        DataShift::Configuration.configure do |config|
          config.remove_rails = true
        end

        DataShift::Transformation::Remove.new.unwanted_columns(headers)

        expect(headers).to_not include [:id, :created_on, :updated_on]
      end

    end

  end

end
