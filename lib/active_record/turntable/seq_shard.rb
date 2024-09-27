module ActiveRecord::Turntable
  class SeqShard < Shard
    def initialize(name = defined?(ActiveRecord::Turntable::RackupFramework) ? ActiveRecord::Turntable::RackupFramework.env : "development")
      super(nil, name)
    end

    def support_slave?
      false
    end

    private

      def connection_class_instance
        if Connections.const_defined?(name.classify)
          klass = Connections.const_get(name.classify)
        else
          klass = Class.new(ActiveRecord::Base)
          Connections.const_set(name.classify, klass)
          klass.abstract_class = true
          config = if ActiveRecord::Base.connection_pool.respond_to?(:db_config)
                     ActiveRecord::Base.connection_pool.db_config.configuration_hash
                   else
                     ActiveRecord::Base.connection_pool.spec.config
                   end
          klass.establish_connection config[:seq][name].with_indifferent_access
        end
        klass
      end
  end
end
