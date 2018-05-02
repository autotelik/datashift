require 'rails/generators/base'

module Datashift
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __dir__)

      desc 'Creates a DataShift initializer within your Rails application.'
      class_option :orm

      def copy_initializer
        template 'datashift.rb', 'config/initializers/datashift.rb'
      end

      def rails_4?
        Rails::VERSION::MAJOR == 4
      end
    end
  end
end
