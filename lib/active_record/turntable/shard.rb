module ActiveRecord::Turntable
  class Shard
    DEFAULT_CONFIG = {
      "connection" => (defined?(ActiveRecord::Turntable::RackupFramework) ? ActiveRecord::Turntable::RackupFramework.env : "development")
    }.with_indifferent_access

    def initialize(shard_spec)
      @config = DEFAULT_CONFIG.merge(shard_spec)
      @name = @config["connection"]
    end

    def connection_pool
      @connection_pool ||= retrieve_connection_pool
    end

    def connection
      connection = connection_pool.connection
      connection.turntable_shard_name = name
      connection
    end

    def name
      @name
    end

    private

    def retrieve_connection_pool
      ActiveRecord::Base.turntable_connections[name] ||=
        begin
          config = ActiveRecord::Base.configurations[ActiveRecord::Turntable::RackupFramework.env]["shards"][name]
          raise ArgumentError, "Unknown database config: #{name}, have #{ActiveRecord::Base.configurations.inspect}" unless config
          ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec_for(config))
        end
    end

    def spec_for(config)
      begin
        adapter = config['adapter'] || config[:adapter]
        require "active_record/connection_adapters/#{adapter}_adapter"
      rescue LoadError => e
        raise "Please install the #{adapter} adapter: `gem install activerecord-#{adapter}-adapter` (#{e})"
      end
      adapter_method = "#{adapter}_connection"
      ActiveRecord::ConnectionAdapters::ConnectionSpecification.new(config, adapter_method)
    end
  end
end

