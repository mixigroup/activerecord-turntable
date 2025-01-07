module ActiveRecord::Turntable::Migration
  extend ActiveSupport::Concern

  included do
    extend ShardDefinition
    prepend OverrideMethods
    class_attribute :target_shards, :current_shard, :target_seqs
    ::ActiveRecord::ConnectionAdapters::AbstractAdapter.include(SchemaStatementsExt)
    ::ActiveRecord::Migration::CommandRecorder.include(CommandRecorder)
  end

  module ShardDefinition
    def clusters(*cluster_names)
      config = ActiveRecord::Base.turntable_configuration
      clusters = config.clusters
      cluster_names = clusters.keys if cluster_names.first == :all
      (self.target_shards ||= []).concat(
          cluster_names.map do |cluster_name|
            clusters[cluster_name].shards.map { |shard| shard.name }
          end.flatten
      )
      (self.target_seqs ||= []).concat(
          cluster_names.map do |cluster_name|
            config.sequencer_registry.cluster_sequencers(clusters[cluster_name]).values.map { |seq| seq.connection.turntable_shard_name }
          end.flatten
      )
    end

    def shards(*connection_names)
      (self.target_shards ||= []).concat connection_names
    end
  end

  module OverrideMethods
    def announce(message)
      if self.current_shard
        super("#{message} - Shard: #{self.current_shard}")
      else
        super("#{message}")
      end
    end

    def exec_migration(*args)
      super(*args) if target_shard?(self.current_shard)
    end

    def target_shard?(shard_name)
      return false if shard_name.present? && target_shards.blank?
      shard_name.nil? or target_shards.blank? or target_shards.include?(shard_name) or target_seqs.include?(shard_name)
    end

    def migrate(*args)
      return super(*args) if target_shards.blank?

      env = ActiveRecord::Turntable::RackupFramework.env || "development"
      config = if ActiveRecord::Turntable::Util.ar_version_equals_or_later?("6.1.0")
                 configs = ActiveRecord::Base.configurations.configs_for(env_name: env.to_s).map(&:configuration_hash)
                 configs.find { |conf| conf.key?("shards") || conf.key?(:shards) }&.stringify_keys
               else
                 ActiveRecord::Base.configurations[env]
               end
      shard_conf = target_shards.map { |shard| [shard, config["shards"][shard]] }.to_h
      seqs_conf = target_seqs.map { |seq| [seq, config["seq"][seq]] }.to_h

      # SHOW FULL FIELDS FROM `users` を実行してテーブルの情報を取得するためにデフォルトのデータベースも追加する
      {"master": config}.merge(shard_conf).merge(seqs_conf).each do |connection_name, database_config|
        next if database_config["database"].blank?
        ActiveRecord::Base.connection_handler.clear_active_connections!
        ActiveRecord::Base.establish_connection(database_config)
        current_shard_name = connection_name == :master ? nil : connection_name
        self.current_shard = current_shard_name
        super(*args)
      end
      ActiveRecord::Base.connection_handler.clear_active_connections!
      ActiveRecord::Base.establish_connection config
      self.current_shard = nil
    end
  end

  module SchemaStatementsExt
    def create_sequence_for(table_name, **options)
      options = options.merge(id: false)

      # TODO: pkname should be pulled from table definitions
      sequence_table_name = ActiveRecord::Turntable::Sequencer.sequence_name(table_name, "id")
      create_table(sequence_table_name, **options) do |t|
        t.integer :id, limit: 8
      end
      execute "INSERT INTO #{quote_table_name(sequence_table_name)} (`id`) VALUES (0)"
    end

    def drop_sequence_for(table_name, **options)
      # TODO: pkname should be pulled from table definitions
      sequence_table_name = ActiveRecord::Turntable::Sequencer.sequence_name(table_name, "id")
      drop_table(sequence_table_name)
    end

    def rename_sequence_for(table_name, new_name)
      # TODO: pkname should pulled from table definitions
      seq_table_name = ActiveRecord::Turntable::Sequencer.sequence_name(table_name, "id")
      new_seq_name = ActiveRecord::Turntable::Sequencer.sequence_name(new_name, "id")
      rename_table(seq_table_name, new_seq_name)
    end
  end

  module CommandRecorder
    def create_sequence_for(*args)
      record(:create_sequence_for, args)
    end

    def rename_sequence_for(*args)
      record(:rename_sequence_for, args)
    end

    private

      def invert_create_sequence_for(args)
        [:drop_sequence_for, args]
      end

      def invert_rename_sequence_for(args)
        [:rename_sequence_for, args.reverse]
      end
  end
end
