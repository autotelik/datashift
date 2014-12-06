# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     Dec 2014
# License::   MIT.
#
# Note, not DataShift, case sensitive, create namespace for command line : datashift
require 'thor'

module DataShift

  class DSThorBase < Thor

    include DataShift::Logging

    no_commands do

      def start_connections()

        # TODO - We're assuming run from a rails app/top level dir...

        if(File.exists?(File.expand_path('config/environment.rb')))
          begin
            require File.expand_path('config/environment.rb')
          rescue => e
            logger.error("Failed to initialise ActiveRecord : #{e.message}")
            raise ConnectionError.new("No config/environment.rb found - cannot initialise ActiveRecord")
          end

        else
          raise PathError.new("No config/environment.rb found - cannot initialise ActiveRecord")
          # TODO make this more robust ? e.g what about when using active record but not in Rails app, Sinatra etc
        end
      end
    end

  end

end
