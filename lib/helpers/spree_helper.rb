# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Spree Helper mixing in Support for testing or loading Rails Spree e-commerce.
# 
#             Since datashift gem is not a Rails app or a Spree App, provides utilities to internally
#             create a Spree Database, and to load Spree components, enabling standalone testing.
#
# =>          Has been tested with 
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
module Spree

  def self.root
    Gem.loaded_specs['spree_core'] ? Gem.loaded_specs['spree_core'].full_gem_path  : ""
  end

  def self.lib_root
    File.join(root, 'lib')
  end

  def self.app_root
    File.join(root, 'app')
  end

  def self.load()
    gem 'spree'
  end
    
  def self.boot
    
    require 'spree'
    require 'spree_core'

    $LOAD_PATH << root << lib_root << app_root << File.join(app_root, 'models')

    require 'spree_core/preferences/model_hooks'
    
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

    require 'product'
    require 'lib/product_filters'
    load_models( true )

  end

  def self.load_models( report_errors = nil )
    puts 'load from', root
    Dir[root + '/app/models/**/*.rb'].each {|r|
      begin
        require r if File.file?(r)
      rescue => e
        puts("WARNING failed to load #{r}", e.inspect) if(report_errors == true)
      end
    }
  end

  def self.migrate_up
    load
    ActiveRecord::Migrator.up( File.join(root, 'db/migrate') )
  end

end
