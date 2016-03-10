namespace :datashift do

  namespace :db do

    SYSTEM_TABLE_EXCLUSION_LIST = ['schema_migrations'].freeze

    desc 'Purge the current database'
    task :purge, [:exclude_system_tables] => [:environment] do |_t, args|
      require 'highline/import'

      if Rails.env.production?
        agree('WARNING: In Production database, REALLY PURGE ? [y]:')
      end

      config = ActiveRecord::Base.configurations[Rails.env || 'development']
      case config['adapter']
      when 'mysql', 'mysql2', 'jdbcmysql'
        ActiveRecord::Base.establish_connection(config)
        ActiveRecord::Base.connection.tables.each do |table|
          next if args[:exclude_system_tables] && SYSTEM_TABLE_EXCLUSION_LIST.include?(table)
          puts "purging table: #{table}"
          ActiveRecord::Base.connection.execute("TRUNCATE #{table}")
        end
      when 'sqlite', 'sqlite3'
        dbfile = config['database'] || config['dbfile']
        File.delete(dbfile) if File.exist?(dbfile)
      when 'sqlserver'
        dropfkscript = "#{config['host']}.#{config['database']}.DP1".tr('\\', '-')
        `osql -E -S #{config['host']} -d #{config['database']} -i db\\#{dropfkscript}`
        `osql -E -S #{config['host']} -d #{config['database']} -i db\\#{Rails.env}_structure.sql`
      when 'oci', 'oracle'
        ActiveRecord::Base.establish_connection(config)
        ActiveRecord::Base.connection.structure_drop.split(";\n\n").each do |ddl|
          ActiveRecord::Base.connection.execute(ddl)
        end
      when 'firebird'
        ActiveRecord::Base.establish_connection(config)
        ActiveRecord::Base.connection.recreate_database!
      else
        raise "Task not supported by '#{config['adapter']}'"
      end
    end

  end
end
