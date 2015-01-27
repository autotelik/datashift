# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
# Details::   A cache type class that stores details of all possible associations on AR classes.
#             
module DataShift

  class MethodDictionary

    include DataShift::Logging
    extend DataShift::Logging

    # Return true if dictionary has  been populated for  klass
    def self.for?(klass)
      any = has_many[klass] || belongs_to[klass] || has_one[klass] || assignments[klass]
      return any != nil
    end
    
    # Create simple picture of all the operator names for assignment available on an AR model,
    # grouped by type of association (includes belongs_to and has_many which provides both << and = )
    # Options:
    #   :reload => clear caches and re-perform  lookup
    #   :instance_methods => if true include instance method type 'setters' as well as model's pure columns
    #
    def self.find_operators(klass, options = {} )
      
      raise "Cannot find operators supplied klass nil #{klass}" if(klass.nil?)

      logger.debug("MethodDictionary - building operators information for #{klass}")

      # Find the has_many associations which can be populated via <<
      if( options[:reload] || has_many[klass].nil? )
        has_many[klass] = klass.reflect_on_all_associations(:has_many).map { |i| i.name.to_s }
        klass.reflect_on_all_associations(:has_and_belongs_to_many).inject(has_many[klass]) { |x,i| x << i.name.to_s }
      end

      # Find the belongs_to associations which can be populated via  Model.belongs_to_name = OtherArModelObject
      if( options[:reload] || belongs_to[klass].nil? )
        belongs_to[klass] = klass.reflect_on_all_associations(:belongs_to).map { |i| i.name.to_s }
      end

      # Find the has_one associations which can be populated via  Model.has_one_name = OtherArModelObject
      if( options[:reload] || has_one[klass].nil? )
        has_one[klass] = klass.reflect_on_all_associations(:has_one).map { |i| i.name.to_s }
      end

      # Find the model's column associations which can be populated via xxxxxx= value
      # Note, not all reflections return method names in same style so we convert all to
      # the raw form i.e without the '='  for consistency 
      if( options[:reload] || assignments[klass].nil? )
 
        assignments[klass] = klass.column_names  
         
        # get into consistent format with other assignments names i.e remove the = for now
        assignments[klass] += setters(klass).map{|i| i.gsub(/=/, '')} if(options[:instance_methods])
           
        # Now remove all the associations
        assignments[klass] -= has_many[klass]   if(has_many[klass])
        assignments[klass] -= belongs_to[klass] if(belongs_to[klass])
        assignments[klass] -= has_one[klass]    if(has_one[klass])
         
        # TODO remove assignments with id
        # assignments => tax_id  but already in belongs_to => tax
        
        assignments[klass].uniq!

        assignments[klass].each do |assign|
          column_types[klass] ||= {}
          column_def = klass.columns.find{ |col| col.name == assign }
          column_types[klass].merge!( assign => column_def) if column_def
        end
      end
    end
    
    def self.setters( klass )
          
      # N.B In 1.8 these return strings, in 1.9 symbols.
      # map everything to strings a
      #setters = klass.accessible_attributes.sort.collect( &:to_s )
      
      # remove methodsa that start with '_'
      @keep_only_pure_setters ||= Regexp.new(/^[a-zA-Z]\w+=/)
      
      setters = klass.instance_methods.grep(@keep_only_pure_setters).sort.collect( &:to_s )
      setters.uniq
    end

    def self.add( klass, operator, type = :assignment)
      method_details_mgr = get_method_details_mgr( klass )
      md = MethodDetail.new(operator, klass, operator, type)
      method_details_mgr <<  md
      return md
    end
    
    # Build a thorough and usable picture of the operators by building dictionary of our MethodDetail
    # objects which can be used to import/export data to objects of type 'klass'
    # Subsequent calls with same class will return existign mapping
    # To over ride this behaviour, supply :force => true to force  regeneration

    def self.build_method_details( klass, options = {} )

      return method_details_mgrs[klass] if(method_details_mgrs[klass] && !options[:force])

      method_details_mgr = MethodDetailsManager.new( klass )
      
      method_details_mgrs[klass] = method_details_mgr
            
      assignments_for(klass).each do |n|
        method_details_mgr << MethodDetail.new(n, klass, n, :assignment, column_types[klass])
      end
        
      has_one_for(klass).each do |n|
        method_details_mgr << MethodDetail.new(n, klass, n, :has_one)
      end
        
      has_many_for(klass).each do |n|
        method_details_mgr << MethodDetail.new(n, klass, n, :has_many)
      end
        
      belongs_to_for(klass).each do |n|
        method_details_mgr << MethodDetail.new(n, klass, n, :belongs_to)
      end
      
      method_details_mgr
      
    end
    
    # TODO - check out regexp to do this work better plus Inflections ??
    # Want to be able to handle any of ["Count On hand", 'count_on_hand', "Count OnHand", "COUNT ONHand" etc]
    def self.substitutions(external_name)
      name = external_name.to_s
      
      [
        name.downcase,
        name.tableize,
        name.gsub(' ', '_'),
        name.gsub(' ', '_').downcase,
        name.gsub(/(\s+)/, '_').downcase,
        name.gsub(' ', ''),
        name.gsub(' ', '').downcase,
        name.gsub(' ', '_').underscore
      ]
    end


    # Dump out all available operators
    #
    def self.dump( klass )
      method_details_mgr = get_method_details_mgr( klass )
      #TODO
    end


    # For a client supplied name/header - find the operator i.e appropriate call + column type
    # 
    # e.g Given users entry in spread sheet check for pluralization, missing underscores etc
    #
    # If not nil, returned method can be used directly in for example klass.new.send( call, .... )
    #
    def self.find_method_detail( klass, external_name, conditions = nil )

      method_details_mgr = get_method_details_mgr( klass )
   
      # first try for an exact match across all association types
      MethodDetail::supported_types_enum.each do |t|
        method_detail = method_details_mgr.find(external_name, t)
        return method_detail.clone if(method_detail)
      end  
              
      # Now try various alternatives of the name
      substitutions(external_name).each do |n|    
        # Try each association type, returning first that contains matching operator with name n    
        MethodDetail::supported_types_enum.each do |t|
          method_detail = method_details_mgr.find(n, t)
          return method_detail.clone if(method_detail)
        end  
      end

      nil
    end
    
    # Assignments can contain things like delegated methods, this returns a matching 
    # method details only when a true database column   
    def self.find_method_detail_if_column( klass, external_name )

      method_details_mgr = get_method_details_mgr( klass )
      
      # first try for an exact match across all association types
      MethodDetail::supported_types_enum.each do |t|
        method_detail = method_details_mgr.find(external_name, t)
        return method_detail.clone if(method_detail && method_detail.col_type) 
      end  
              
      # Now try various alternatives
      substitutions(external_name).each do |n|    
        # Try each association type, returning first that contains matching operator with name n    
        MethodDetail::supported_types_enum.each do |t|
          method_detail = method_details_mgr.find(n, t)
          return method_detail.clone if(method_detail && method_detail.col_type) 
        end  
      end

      nil
    end
    
    
    def self.clear
      belongs_to.clear
      has_many.clear
      assignments.clear
      column_types.clear
      has_one.clear
      method_details_mgrs.clear
    end

    def self.column_key(klass, column)
      "#{klass.name}:#{column}"
    end
    
    def self.get_method_details_mgr( klass )
      method_details_mgrs[klass] || MethodDetailsManager.new( klass )
    end
    
    
    # Store a Mgr per mapped klass
    def self.method_details_mgrs
      @method_details_mgrs ||= {}
      @method_details_mgrs
    end

    def self.belongs_to
      @belongs_to ||={}
      @belongs_to
    end

    def self.has_many
      @has_many ||= {}
      @has_many
    end

    def self.has_one
      @has_one ||= {}
      @has_one
    end

    def self.assignments
      @assignments ||= {}
      @assignments
    end
    
    def self.column_types
      @column_types ||= {}
      @column_types  
    end


    def self.belongs_to_for(klass)
      belongs_to[klass] || []
    end
    
    def self.has_many_for(klass)
      has_many[klass] || []
    end

    def self.has_one_for(klass)
      has_one[klass] || []
    end

    def self.assignments_for(klass)
      assignments[klass] || []
    end
    
    def self.column_type_for(klass, column)
      column_types[klass] ?  column_types[klass][column] : []
    end
  
  end

end