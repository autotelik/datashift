# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Specs for base class Loader
#
require File.dirname(__FILE__) + '/spec_helper'

module DataShift

  describe '#configure' do
    let(:defaults) {
      { project:
            { value_as_string: 'Default Project Value',
              category: 'reference:category_002',
              value_as_datetime:  Time.now.to_s(:db)
            }
      }
    }

    before do
      DataShift.configure do |config|
        config.datashift_defaults = defaults
      end
    end

    it 'returns hash with 3 elements' do
      draw = MegaLotto::Drawing.new.draw

      expect(draw).to be_a(Array)
      expect(draw.size).to eq(10)
    end
  end

end
