module ActiveRecord::Turntable
  module ActiveRecordExt
    module Persistence
      extend ActiveSupport::Concern

      ::ActiveRecord::Persistence.class_eval do
        # @note Override to add sharding scope on reloading
        def reload(options = nil)
          self.class.connection.clear_query_cache

          fresh_object = if turntable_enabled? && self.class.primary_key != self.class.turntable_shard_key.to_s
                           if apply_scoping?(options)
                             _find_record_with_shard(options)
                           else
                             self.class.unscoped { _find_record_with_shard(options) }
                           end
                         else
                           if apply_scoping?(options)
                             _find_record(options)
                           else
                             self.class.unscoped { _find_record(options) }
                           end
                         end

          @association_cache = fresh_object.instance_variable_get(:@association_cache)
          @attributes = fresh_object.instance_variable_get(:@attributes)
          @new_record = false
          @previously_new_record = false
          self
        end

        def _find_record_with_shard(options)
          if options && options[:lock]
            self.class.preload(strict_loaded_associations).where(self.class.turntable_shard_key => self.send(turntable_shard_key)).lock(options[:lock]).find(id)
          else
            self.class.preload(strict_loaded_associations).where(self.class.turntable_shard_key => self.send(turntable_shard_key)).find(id)
          end
        end

        private

        # @note Override to add sharding scope on `_query_constraints_hash`
        def _query_constraints_hash
          h = { @primary_key => id_in_database }
          return h unless self.class.sharding_condition_needed?

          h.merge(self.class.turntable_shard_key => self[self.class.turntable_shard_key])
        end
      end
    end
  end
end
