# Copyright:: Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     April 2016
# License::
#
#
if DataShift::Guards.jruby?
  module Java
    module OrgApachePoiHssfUsermodel

      class HSSFSheet
        def name
          getSheetName
        end

        def num_rows
          getPhysicalNumberOfRows
        end

      end

    end
  end
end