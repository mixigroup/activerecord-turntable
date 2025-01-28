module ActiveRecord::Turntable
  module ActiveRecordExt
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :AbstractAdapter
      autoload :CleverLoad
      autoload :ConnectionHandlerExtension
      autoload :LogSubscriber
      autoload :Persistence
      autoload :SchemaDumper
      autoload :Sequencer
      autoload :Relation
      autoload :Transactions
      autoload :AssociationPreloader
      autoload :Association
      autoload :LockingOptimistic
      autoload :QueryCache
    end

    included do
      include Transactions
      ActiveRecord::Base.prepend(Sequencer)
      ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(AbstractAdapter)
      ActiveRecord::LogSubscriber.prepend(LogSubscriber)
      ActiveRecord::Persistence.include(Persistence)
      ActiveRecord::Relation.include(CleverLoad)
      ActiveRecord::Migration.include(ActiveRecord::Turntable::Migration)
      ActiveRecord::ConnectionAdapters::ConnectionHandler.prepend(ConnectionHandlerExtension)
      ActiveRecord::Associations::Preloader::Association.prepend(AssociationPreloader)
      ActiveRecord::Associations::Association.prepend(Association)
      ActiveRecord::Associations::Builder::Association.singleton_class.prepend(Builder::Association)
      ActiveRecord::QueryCache.prepend(QueryCache)
      require "active_record/turntable/active_record_ext/fixtures"
      require "active_record/turntable/active_record_ext/migration_proxy"
      require "active_record/turntable/active_record_ext/activerecord_import_ext"
      require "active_record/turntable/active_record_ext/acts_as_archive_extension"
    end
  end
end
