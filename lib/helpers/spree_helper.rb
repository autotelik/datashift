# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Spree Helper for Product Loading. 
# 
#             Utils to try to manage different Spree versions seamlessly.
#             
#             Spree Helper for RSpec testing, enables mixing in Support for
#             testing or loading Rails Spree e-commerce.
# 
#             The Spree version you want to test should be picked up from spec/Gemfile
# 
#             Since datashift gem is not a Rails app or a Spree App, provides utilities to internally
#             create a Spree Database, and to load Spree components, enabling standalone testing.
#
# =>          Has been tested with  0.11.2, 0.7, 1.0.0
#
# =>          TODO - See if we can improve DB creation/migration ....
#             N.B Some or all of Spree Tests may fail very first time run,
#             as the database is auto generated
# =>          

module DataShift
    
  module SpreeHelper
            
    def self.root
      Gem.loaded_specs['spree_core'] ? Gem.loaded_specs['spree_core'].full_gem_path  : ""
    end
    
    # Helpers so we can cope with both pre 1.0 and post 1.0 versions of Spree in same datashift version

    def self.get_spree_class(x)
      if(is_namespace_version())    
        ModelMapper::class_from_string("Spree::#{x}")
      else
        ModelMapper::class_from_string(x.to_s)
      end
    end
      
    def self.get_product_class
      if(is_namespace_version())
        Spree::Product
      else
        Product
      end
    end
    
    def self.version
       Gem.loaded_specs['spree'] ? Gem.loaded_specs['spree'].version.version : "0.0.0"
    end
    
    def self.is_namespace_version
      SpreeHelper::version.to_f >= 1
    end
  
    def self.lib_root
      File.join(root, 'lib')
    end

    def self.app_root
      File.join(root, 'app')
    end

    def self.load()
      require 'spree'
      require 'spree_core'
    end
    
    
    # Datashift is usually included and tasks pulled in by a parent/host application.
    # So here we are hacking our way around the fact that datashift is not a Rails/Spree app/engine
    # so that we can ** run our specs ** directly in datashift library
    # i.e without ever having to install datashift in a host application
    #
    # NOTES:
    # => Will chdir into the sandbox to load environment as need to mimic being at root of a rails project
    #    chdir back after environment loaded
    
    def self.boot( database_env)
     
      db_clear_connections
      
      if( ! is_namespace_version )
        
        SpreeHelper.load() 
        
        db_connect( database_env )
        @dslog.info "Booting Spree using pre 1.0.0 version"
        boot_pre_1
        @dslog.info "Booted Spree using pre 1.0.0 version"
      else

        #require 'rails/all'
        
        store_path = Dir.pwd
        
        spree_sanbox_app = File.expand_path('../../../spec/sandbox', __FILE__)
        
        unless(File.exists?(spree_sanbox_app))
          puts "Creating new Rails sandbox for Spree : #{spree_sanbox_app}"
          Dir.chdir( File.expand_path( "#{spree_sanbox_app}/..") )
          system('rails new sandbox')
        end
  
        puts "Using Rails sandbox for Spree : #{spree_sanbox_app}"
        
        rails_root = spree_sanbox_app
        
        $:.unshift rails_root
        
        begin
          require 'config/environment.rb'
        rescue => e
          #somethign in deface seems to blow up suddenly on 1.1
          puts "Warning - Potential issue initializing Spree sandbox:"
          puts e.backtrace
          puts "#{e.inspect}"
        end
        
        set_logger
        
        Dir.chdir( store_path )
        
        @dslog.info "Booted Spree using version #{SpreeHelper::version}"
      end
    end

    def self.boot_pre_1
 
      require 'rake'
      require 'rubygems/package_task'
      require 'thor/group'

      require 'spree_core/preferences/model_hooks'
      #
      # Initialize preference system
      ActiveRecord::Base.class_eval do
        include Spree::Preferences
        include Spree::Preferences::ModelHooks
      end
 
      gem 'paperclip'
      gem 'nested_set'

      require 'nested_set'
      require 'paperclip'
      require 'acts_as_list'

      CollectiveIdea::Acts::NestedSet::Railtie.extend_active_record
      ActiveRecord::Base.send(:include, Paperclip::Glue)

      gem 'activemerchant'
      require 'active_merchant'
      require 'active_merchant/billing/gateway'

      ActiveRecord::Base.send(:include, ActiveMerchant::Billing)
  
      require 'scopes'
    
      # Not sure how Rails manages this seems lots of circular dependencies so
      # keep trying stuff till no more errors
    
      Dir[lib_root + '/*.rb'].each do |r|
        begin
          require r if File.file?(r)  
        rescue => e
        end
      end

      Dir[lib_root + '/**/*.rb'].each do |r|
        begin
          require r if File.file?(r) && ! r.include?('testing')  && ! r.include?('generators')
        rescue => e
        end
      end
    
      load_models( true )

      Dir[lib_root + '/*.rb'].each do |r|
        begin
          require r if File.file?(r)  
        rescue => e
        end
      end

      Dir[lib_root + '/**/*.rb'].each do |r|
        begin
          require r if File.file?(r) && ! r.include?('testing')  && ! r.include?('generators')
        rescue => e
        end
      end

      #  require 'lib/product_filters'
     
      load_models( true )

    end
  
    def self.load_models( report_errors = nil )
      puts 'Loading Spree models from', root
      Dir[root + '/app/models/**/*.rb'].each {|r|
        begin
          require r if File.file?(r)
        rescue => e
          puts("WARNING failed to load #{r}", e.inspect) if(report_errors == true)
        end
      }
    end

    def self.migrate_up
      ActiveRecord::Migrator.up( File.join(root, 'db/migrate') )
    end

  end
end 