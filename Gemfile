source 'https://rubygems.org'

# Declare your gem's dependencies in gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

group :test do

  gem 'byebug'
  gem 'ffaker'
  gem 'rspec-rails', '~> 3.4'

  platform :jruby do
    gem 'jruby-openssl'
    gem 'activerecord-jdbcsqlite3-adapter'

    # ruby "2.2.0", engine: "jruby"  #, engine_version: "~> 9.0"
  end

  platform :ruby do
    gem 'sqlite3', '~> 1.3'
  end

  gem 'simplecov'
  gem 'codeclimate-test-reporter', '~> 1.0.0'

end
