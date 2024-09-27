require "active_record/tasks/database_tasks"
require "active_record/turntable/util"

module ActiveRecord
  module Tasks
    module DatabaseTasks
      def env
        @env ||= ActiveRecord::Turntable::RackupFramework.env
      end

      def create_all_turntable_cluster
        each_local_turntable_cluster_configuration { |_name, configuration|
          puts "[turntable] *** executing to database: #{configuration['database']}"
          create configuration
        }
      end

      def drop_all_turntable_cluster
        each_local_turntable_cluster_configuration { |_name, configuration|
          puts "[turntable] *** executing to database: #{configuration['database']}"
          drop configuration
        }
      end

      def create_current_turntable_cluster(environment = env)
        each_current_turntable_cluster_configuration(environment) { |_name, configuration|
          puts "[turntable] *** executing to database: #{configuration['database']}"
          create configuration
        }
        ActiveRecord::Base.establish_connection environment.to_sym
      end

      def drop_current_turntable_cluster(environment = env)
        each_current_turntable_cluster_configuration(environment) { |_name, configuration|
          puts "[turntable] *** executing to database: #{configuration['database']}"
          drop configuration
        }
      end

      def each_current_turntable_cluster_connected(environment)
        old_connection_pool = ActiveRecord::Base.connection_pool
        each_current_turntable_cluster_configuration(environment) do |name, configuration|
          ActiveRecord::Base.clear_active_connections!
          ActiveRecord::Base.establish_connection(configuration)
          ActiveRecord::Migration.current_shard = name
          yield(name, configuration)
        end
        ActiveRecord::Base.clear_active_connections!
        config = if old_connection_pool.respond_to?(:db_config)
                   old_connection_pool.db_config.configuration_hash
                 else
                   old_connection_pool.spec.config
                 end
        ActiveRecord::Base.establish_connection config
      end

      def each_current_turntable_cluster_configuration(environment)
        environments = [environment]
        environments << "test" if environment == "development"

        current_turntable_cluster_configurations(*environments).each do |name, configuration|
          yield(name, configuration) unless configuration["database"].blank?
        end
      end

      def each_local_turntable_cluster_configuration
        ActiveRecord::Base.configurations.keys.each do |k|
          current_turntable_cluster_configurations(k).each do |name, configuration|
            next if configuration["database"].blank?

            if local_database?(configuration)
              yield(name, configuration)
            else
              $stderr.puts "This task only modifies local databases. #{configuration['database']} is on a remote host."
            end
          end
        end
      end

      def current_turntable_cluster_configurations(*environments)
        configurations = []
        environments.each do |environ|
          config = if ActiveRecord::Turntable::Util.ar61_or_later?
                     configs = ActiveRecord::Base.configurations.configs_for(env_name: environ.to_s).map(&:configuration_hash)
                     configs&.find { |conf| conf.key?("shards") || conf.key?(:shards) }&.stringify_keys
                   else
                     ActiveRecord::Base.configurations[environ]
                   end
          next unless config
          %w(shards seq).each do |name|
            configurations += config[name].to_a if config.has_key?(name)
          end
        end
        configurations
      end
    end
  end
end
