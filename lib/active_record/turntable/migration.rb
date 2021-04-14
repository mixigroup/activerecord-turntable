module ActiveRecord::Turntable::Migration
  extend ActiveSupport::Concern

  included do
    extend ShardDefinition
    class_attribute :target_shards, :current_shard, :target_seqs
    alias_method_chain :announce, :turntable
    alias_method_chain :migrate, :turntable
    alias_method_chain :exec_migration, :turntable
    ::ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, SchemaStatementsExt)
    ::ActiveRecord::Migration::CommandRecorder.send(:include, CommandRecorder)
    ::ActiveRecord::Migrator.send(:include, Migrator)
  end

  module ShardDefinition
    def clusters(*cluster_names)
      config = ActiveRecord::Base.turntable_config["clusters"]
      cluster_names = config.keys if cluster_names.first == :all
      (self.target_shards ||= []).concat(
          cluster_names.map do |cluster_name|
            config[cluster_name]["shards"].map { |shard| shard["connection"] }
          end.flatten
      )
      (self.target_seqs ||= []).concat(
          cluster_names.map do |cluster_name|
            config[cluster_name]["seq"].values.map { |seq| seq["connection"] }
          end.flatten
      )
    end

    def shards(*connection_names)
      (self.target_shards ||= []).concat connection_names
    end
  end

  def target_shard?(shard_name)
    return false if shard_name.present? && target_shards.blank?
    shard_name.nil? or target_shards.blank? or target_shards.include?(shard_name)
  end

  def announce_with_turntable(message)
    announce_without_turntable("#{message} - Shard: #{current_shard}")
  end

  def exec_migration_with_turntable(*args)
    exec_migration_without_turntable(*args) # if target_shard?(current_shard)
  end

  def migrate_with_turntable(*args)
    return migrate_without_turntable(*args) if target_shards.blank?

    config = ActiveRecord::Base.configurations[ActiveRecord::Turntable::RackupFramework.env||"development"]
    shard_conf = target_shards.map { |shard| [shard, config["shards"][shard]] }.to_h
    seqs_conf = target_seqs.map { |seq| [seq, config["seq"][seq]] }.to_h

    # SHOW FULL FIELDS FROM `users` を実行してテーブルの情報を取得するためにデフォルトのデータベースも追加する
    {"master": config}.merge(shard_conf).merge(seqs_conf).each do |connection_name, database_config|
      next if database_config["database"].blank?
      ActiveRecord::Base.clear_active_connections!
      ActiveRecord::Base.establish_connection(database_config)
      ActiveRecord::Migration.current_shard = connection_name
      migrate_without_turntable(*args)
    end
    ActiveRecord::Base.establish_connection config
    ActiveRecord::Base.clear_active_connections!
  end

  module SchemaStatementsExt
    def create_sequence_for(table_name, options = { })
      options = options.merge(:id => false)

      # TODO: pkname should be pulled from table definitions
      pkname = "id"
      sequence_table_name = ActiveRecord::Turntable::Sequencer.sequence_name(table_name, "id")
      create_table(sequence_table_name, options) do |t|
        t.integer :id, :limit => 8
      end
      execute "INSERT INTO #{quote_table_name(sequence_table_name)} (`id`) VALUES (0)"
    end

    def drop_sequence_for(table_name, options = { })
      # TODO: pkname should be pulled from table definitions
      pkname = "id"
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

  module Migrator
    extend ActiveSupport::Concern

    included do
      klass = self
      (class << klass; self; end).instance_eval {
        [:up, :down, :run].each do |method_name|
          original_method_alias = "_original_#{method_name}"
          unless klass.respond_to?(original_method_alias)
            alias_method original_method_alias, method_name
          end
          alias_method_chain method_name, :turntable
        end
      }
    end

    module ClassMethods
      def up_with_turntable(migrations_paths, target_version = nil)
        up_without_turntable(migrations_paths, target_version)

        # ActiveRecord::Tasks::DatabaseTasks.each_current_turntable_cluster_connected do |name, configuration|
        #   puts "[turntable] *** Migrating database: #{configuration['database']}(Shard: #{name})"
        #   _original_up(migrations_paths, target_version)
        # end
      end

      def down_with_turntable(migrations_paths, target_version = nil, &block)
        down_without_turntable(migrations_paths, target_version, &block)

        # ActiveRecord::Tasks::DatabaseTasks.each_current_turntable_cluster_connected do |name, configuration|
        #   puts "[turntable] *** Migrating database: #{configuration['database']}(Shard: #{name})"
        #   _original_down(migrations_paths, target_version, &block)
        # end
      end

      def run_with_turntable(*args)
        run_without_turntable(*args)

        # ActiveRecord::Tasks::DatabaseTasks.each_current_turntable_cluster_connected do |name, configuration|
        #   puts "[turntable] *** Migrating database: #{configuration['database']}(Shard: #{name})"
        #   _original_run(*args)
        # end
      end
    end
  end
end
