source "http://rubygems.org"
# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.


# We leave it up to the main Rails app to define the actual versions required
group :development do
  gem "rails"
  gem "activerecord"
  gem "activesupport"
  
  platform :jruby do
    gem 'jruby-openssl'
    gem 'activerecord-jdbcsqlite3-adapter'
  end
  
  gem 'spree', '0.70.3'
  gem "rspec", ">= 0"
  gem "shoulda", ">= 0"
  gem "rdoc", "~> 3.12"
  gem "bundler", "~> 1.0.0"
  gem "jeweler", "~> 1.8.3"
end

