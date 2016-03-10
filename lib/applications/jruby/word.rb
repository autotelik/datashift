# Author::    Tom Statter
# License::   MIT ?
#
# NOTES ON INVESTIGATING OLE METHODS in irb
#
# visible = @word_app.ole_method_help( 'Visible' )   # Get a Method Object

# log( visible.return_type_detail.to_s )           # => ["BOOL"]
# log( visible.invoke_kind.to_s )                  # => "PROPERTYGET"
# log( visible.params.to_s )                       # => []

# @fc.ole_method_help( 'Report' ).params[1].ole_type_detail
#
# prefs = @word_app.Preferences.Strings.ole_method_help( 'Set' ).params
#   => [index, newVal]
#
# WORD_OLE_CONST.constants
#
# WORD_OLE_CONST.constants.sort.grep /CR/
#   => ["ClHideCRLF", "LesCR", "LesCRLF"]
#
# WORD_OLE_CONST.const_get( 'LesCR' ) or WORD_OLE_CONST::LesCR
#   => 1

if Guards.windows?

  require 'win32ole'

  # Module for constants to be loaded int

  module WORD_OLE_CONST
  end

  class Word

    attr_reader :wd, :doc

    def initialize( visible )
      @wd = WIN32OLE.new('Word.Application')

      WIN32OLE.const_load(@wd, WORD_OLE_CONST) if WORD_OLE_CONST.constants.empty?

      @wd.Visible = visible
    end

    def open(file)
      @doc = @wd.Documents.Open(file)
      @doc
    end

    def save
      @doc.Save()
      @doc
    end

    # Format : From WORD_OLE_CONST e.g WORD_OLE_CONST::WdFormatHTML
    #
    def save_as(name, format)
      @doc.SaveAs(name, format)
      @doc
    end

    # WdFormatFilteredHTML
    # WdFormatHTML
    def save_as_html(name)
      @doc.SaveAs(name, WORD_OLE_CONST::WdFormatHTML)
      @doc
    end

    def quit
      @wd.quit
    end
  end

else

  class Word
  end
end
