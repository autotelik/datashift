# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Export a model to CSV
#
#
require 'exporter_base'
require 'csv'

module DataShift

  class CsvExporter < ExporterBase

    attr_accessor :text_delim
    
    def initialize(filename)
      super(filename)
      @text_delim = "\'"
    end

    # Return opposite of text delim - "hello, 'barry'" => '"hello, "barry""'
    def escape_text_delim
      return '"' if @text_delim == "\'"
      "\'"
    end
    
    # Create CSV file from set of ActiveRecord objects
    # Options :
    # => :filename
    # => :text_delim => Char to use to delim columns, useful when data contain embedded ','
    # => ::methods => List of methods to additionally call on each record
    #
    def export(records, options = {})
       
      raise ArgumentError.new('Please supply array of records to export') unless records.is_a? Array
      
      first = records[0]
     
      return unless(first.is_a?(ActiveRecord::Base))
      
      f = options[:filename] || filename()
      
      @text_delim = options[:text_delim] if(options[:text_delim])
      
      File.open(f, "w") do |csv|
        
        headers = first.serializable_hash.keys
           
        [*options[:methods]].each do |c| headers << c if(first.respond_to?(c)) end if(options[:methods])
             
        csv << headers.join(Delimiters::csv_delim) << Delimiters::eol
        
        records.each do |r|
          next unless(r.is_a?(ActiveRecord::Base))
          
          csv << record_to_csv(r, options) << Delimiters::eol
        end
      end
    end
      
    # Create an Excel file from list of ActiveRecord objects
    # Specify which associations to export via :with or :exclude
    # Possible values are : [:assignment, :belongs_to, :has_one, :has_many]
    #
    def export_with_associations(klass, records, options = {})
        
      f = options[:filename] || filename()
      
      @text_delim = options[:text_delim] if(options[:text_delim])
       
      MethodDictionary.find_operators( klass )
        
      # builds all possible operators
      MethodDictionary.build_method_details( klass )
           
      work_list = options[:with] ? Set(options[:with]) : MethodDetail::supported_types_enum
      
      assoc_work_list = work_list.dup

      details_mgr = MethodDictionary.method_details_mgrs[klass]

      headers, assoc_operators, assignments = [], [], []
      
      # headers
      if(work_list.include?(:assignment))
        assignments << details_mgr.get_list(:assignment).collect( &:operator)
        assoc_work_list.delete :assignment
      end
         
      headers << assignments.flatten!
      # based on users requested list ... belongs_to has_one, has_many etc ... select only those operators
      assoc_operators = assoc_work_list.collect do |op_type|     
        details_mgr.get_list(op_type).collect(&:operator).flatten
      end
      
      assoc_operators.flatten!
      
      File.open(f, "w") do |csv|  
          
        csv << headers.join(Delimiters::csv_delim)
        
        csv << Delimiters::csv_delim << assoc_operators.join(Delimiters::csv_delim) unless(assoc_operators.empty?)
        
        csv << Delimiters::eol
        
        records.each do |r|
          next unless(r.is_a?(ActiveRecord::Base))
          
          csv_columns = []
          # need to make sure order matches headers
          # could look at collection headers via serializable hash.keys and then use 
          # csv << record_to_csv(r) ??
          assignments.each {|x| csv << escape(r.send(x)) << Delimiters::csv_delim }
                 
          # done records basic attributes now deal with associations
          
          #assoc_work_list.each do |op_type| 
           # details_mgr.get_operators(op_type).each do |operator| 
          assoc_operators.each do |operator| 
              assoc_object = r.send(operator) 
              
              if(assoc_object.is_a?ActiveRecord::Base)
                column_text = record_to_column(assoc_object)     # belongs_to or has_one
                
              # TODO -ColumnPacker class shared between excel/csv
              
                csv << "#{@text_delim}#{column_text}#{@text_delim}" << Delimiters::csv_delim
                #csv << record_to_csv(r)
                
              elsif(assoc_object.is_a? Array)
                items_to_s = assoc_object.collect {|x| record_to_column(x) }
                
                # create a single column
                csv << "#{@text_delim}#{items_to_s.join(Delimiters::multi_assoc_delim)}#{@text_delim}" << Delimiters::csv_delim
                
              else
                csv << Delimiters::csv_delim
              end
            #end
          end
          
          csv << Delimiters::eol   # next record
          
        end
      end
    end
    
  
    # Convert an AR instance to a single CSV column
  
    def record_to_column(record) 
    
      csv_data = []
      record.serializable_hash.each do |name, value|
        value = 'nil' if value.nil?
        text = value.to_s.gsub(@text_delim, escape_text_delim())
        csv_data << "#{name.to_sym} => #{text}"
      end
      "#{csv_data.join(Delimiters::csv_delim)}"
    end
    
    
    # Convert an AR instance to a set of CSV columns
    def record_to_csv(record, options = {})
      csv_data = record.serializable_hash.values.collect { |value| escape(value) }

      [*options[:methods]].each { |x| csv_data << escape(record.send(x)) if(record.respond_to?(x)) } if(options[:methods])
      
      csv_data.join( Delimiters::csv_delim )
    end
    

    private

    def escape(value)
      text = value.to_s.gsub(@text_delim, escape_text_delim())
      
      text = "#{@text_delim}#{text}#{@text_delim}" if(text.include?(Delimiters::csv_delim)) 
      text
    end
    
  end
end
