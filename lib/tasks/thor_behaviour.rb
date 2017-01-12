# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT.
#
module DataShift

  module ThorBehavior

    include DataShift::Logging

    def start_connections

      if File.exist?(File.expand_path('config/environment.rb'))
        begin
          require File.expand_path('config/environment.rb')
        rescue => e
          logger.error("Failed to initialise ActiveRecord : #{e.message}")
          raise ConnectionError, "Failed to initialise ActiveRecord : #{e.message}"
        end

      else
        raise PathError, 'No config/environment.rb found - cannot initialise ActiveRecord'
        # TODO: make this more robust ? e.g what about when using active record but not in Rails app, Sinatra etc
      end
    end
  end

end
