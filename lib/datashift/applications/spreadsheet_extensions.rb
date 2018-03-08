# Copyright:: Autotelik Media Ltd
# Author ::   Tom Statter
# Date ::     July 2010
# License::
#
#
# Extend the Spreadsheet classes with some of our common methods
#
# ... to do extract into separate module with pure ruby that works with both POI and Spreadsheet

require 'excel_base'

module Spreadsheet

  class Worksheet

    include DataShift::ExcelBase

    # See Spreadsheet::Format
    attr_accessor :header_format

    # Convert array into a header row

    def set_headers(headers, _apply_style = nil)
      return if headers.empty?

      format = header_format || Spreadsheet::Format.new(color: :blue, weight: :bold, size: 12)
      row(0).default_format = format

      headers.each_with_index do |header, i|
        self[0, i] = header.to_s
      end
    end

    def auto_fit_columns
      (0...column_count).each do |col_idx|
        column = column(col_idx)

        column.width = column.each_with_index.map do |cell, row|
          chars = cell.present? ? cell.to_s.strip.split('').count + 3 : 1
          ratio = row(row).format(col_idx).font.size / 10.0
          (chars * ratio).round
        end.max
      end
      self
    end

    def auto_fit_rows
      (0...row_count).each do |row_idx|
        row = row(row_idx)
        row.height = row.each_with_index.map do |cell, col_idx|
          lines = cell.present? ? cell.to_s.strip.split("\n").count + 1 : 1
          lines * row.format(col_idx).font.size
        end.max.round
      end
      self
    end

    def num_rows
      rows.size
    end

  end
end
