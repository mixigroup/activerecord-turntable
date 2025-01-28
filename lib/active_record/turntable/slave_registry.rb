module ActiveRecord::Turntable
  class SlaveRegistry
    thread_mattr_accessor :registry

    def self.slave_for(shard)
      SlaveRegistry.registry ||= Hash.new { |h, k| h[k] = {} }
      SlaveRegistry.registry[shard][:current_slave]
    end

    def self.set_slave_for(shard, target_slave)
      SlaveRegistry.registry ||= Hash.new { |h, k| h[k] = {} }
      SlaveRegistry.registry[shard][:current_slave] = target_slave
    end

    def self.clear_for!(shard)
      SlaveRegistry.registry ||= Hash.new { |h, k| h[k] = {} }
      SlaveRegistry.registry[shard].clear
    end
  end
end
