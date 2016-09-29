DB_CLEANER_TRUNCATION_OPTS = {} # except: %w(projects) }.freeze

RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation, DB_CLEANER_TRUNCATION_OPTS
    DatabaseCleaner.clean_with(:truncation)


    begin
      DatabaseCleaner.start
    ensure
      DatabaseCleaner.clean
    end
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.append_after(:each) do
    DatabaseCleaner.clean
  end
end
