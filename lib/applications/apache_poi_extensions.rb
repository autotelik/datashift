# Copyright:: Autotelik Media Ltd
# Author ::   Tom Statter
# Date ::     July 2010
# License::
#
#
if DataShift::Guards.jruby?

  require 'java'
  require 'poi-3.7-20101029.jar'

  # Extend the Poi classes with some syntactic sugar

  java_import 'org.apache.poi.ss.util.CellReference'

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
