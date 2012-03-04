# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Spree Helper mixing in Support for testing or loading Rails Spree e-commerce.
# 
#             The Spree version you want to test should be picked up from the Gemfile
# 
#             Since datashift gem is not a Rails app or a Spree App, provides utilities to internally
#             create a Spree Database, and to load Spree components, enabling standalone testing.
#
# =>          Has been tested with  0.7
# 
# # =>        TODO - Can we move to a Gemfile/bunlder
#             require 'rubygems'
#             gemfile = File.expand_path("<%= gemfile_path %>", __FILE__)
#
#             ENV['BUNDLE_GEMFILE'] = gemfile
#             require 'bundler'
#             Bundler.setup
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

    def self.get_product_class
      if(is_namespace_version())
          Spree::Product
        else
          Product
        end
    end
    
    def self.is_namespace_version
      Gem.loaded_specs['spree'].version.version.to_f >= 1
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
    
    
    # Datahift isi usually included and tasks pulled in by a parent/host application.
    # So here we are hacking our way around the fact that datashift is not a Rails/Spree app/engine
    # so that we can ** run our specs ** directly in datashift library
    # i.e without ever having to install datashift in a host application
    def self.boot( database_env )
     
      if( ! is_namespace_version )
       db_connect( database_env )   
       boot_pre_1
      else
        
        gem('rails', '3.1.3')
        
        db_connect( database_env, '3.1.3' )  
        puts "New Spree 1.0.0 Spec Boot"
        
        require 'rails/all'

        Dir.chdir( File.expand_path('../../../sandbox', __FILE__) )
        
        puts "New Spree 1.0.0 Spec Boot"
       
        require 'rails/all'

        require 'config/environment'
        
        # == Booting process
        #
        # The application is also responsible for setting up and executing the booting
        # process. From the moment you require "config/application.rb" in your app,
        # the booting process goes like this:
        #
        #   1)  require "config/boot.rb" to setup load paths
        #   2)  require railties and engines
        #   3)  Define Rails.application as "class MyApp::Application < Rails::Application"
        #   4)  Run config.before_configuration callbacks
        #   5)  Load config/environments/ENV.rb
        #   6)  Run config.before_initialize callbacks
        #   7)  Run Railtie#initializer defined by railties, engines and application.
        #       One by one, each engine sets up its load paths, routes and runs its config/initializers/* files.
        #   9)  Custom Railtie#initializers added by railties, engines and applications are executed
        #   10) Build the middleware stack and run to_prepare callbacks
        #   11) Run config.before_eager_load and eager_load if cache classes is true
        #   12) Run config.after_initialize callbacks
                
        puts Rails.methods.sort.inspect
        
        puts ActiveRecord::Base.configurations.inspect
        puts ActiveRecord::Base.configurations.class.inspect
        
            
        puts Rails.configuration.class.inspect
        
        puts Rails.configuration.inspect
        
        Rails.configuration.database_configuration[Rails.env]
        
        puts "1",Rails.configuration.database_configuration[Rails.env]
        
        puts "2",Rails.configuration.database_configuration[Rails.env]['adapter'].to_sym
        
        puts "Spree booted"
        #require File.expand_path( SpreeHelper::lib_root + '/generators/spree/install/install_generator')
        #require 'spree/core/testing_support/common_rake'


        #Spree::SandboxGenerator.start ["--lib_name=spree", "--database=#{ENV['DB_NAME']}"]
        #Spree::InstallGenerator.start ["--auto-accept"]

        #cmd = "bundle exec rake assets:precompile:nondigest"; 
        #puts cmd; system cmd
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