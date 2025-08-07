module ActiveRecord::Turntable
  module ActiveRecordExt
    module Transactions
      # @note Override to start transaction on current shard
      def with_transaction_returning_status
        klass = self.class
        return super unless klass.turntable_enabled?
        ensure_finalize = !klass.connection.transaction_open? if Util.ar61_or_later?

        status = nil
        # trilogy が auto increment ベースで INSERT 後の ID を取得しようとするため
        # new_record の場合は、常に ID へ sequencer の値をセットする
        if self.new_record? && self.id.nil? && klass.prefetch_primary_key?
          self.id = klass.next_sequence_value
        end
        self.class.connection.shards_transaction([self.turntable_shard]) do
          if Util.ar61_or_later?
            add_to_transaction(ensure_finalize || has_transactional_callbacks?)
            remember_transaction_record_state
          elsif Util.ar60_or_later?
            if has_transactional_callbacks?
              add_to_transaction
            else
              sync_with_transaction_state if @transaction_state&.finalized?
              @transaction_state = self.turntable_shard.connection.transaction_state
            end
            remember_transaction_record_state
          else
            add_to_transaction
          end

          begin
            status = yield
          rescue ActiveRecord::Rollback
            clear_transaction_record_state
            status = nil
          end

          raise ActiveRecord::Rollback unless status
        end
        status
      ensure
        if !Util.ar60_or_later? && @transaction_state && @transaction_state.committed?
          clear_transaction_record_state
        end
      end

      if Util.ar_version_equals_or_later?("6.1.0")
        def add_to_transaction(ensure_finalize = true)
          return super unless self.class.turntable_enabled?
          self.turntable_shard.connection.add_transaction_record(self, ensure_finalize)
        end
      else
        def add_to_transaction
          return super unless self.class.turntable_enabled?

          if Util.ar60_or_later?
            self.turntable_shard.connection.add_transaction_record(self)
          else
            if has_transactional_callbacks?
              self.turntable_shard.connection.add_transaction_record(self)
            else
              sync_with_transaction_state
              set_transaction_state(self.turntable_shard.connection.transaction_state)
            end
            remember_transaction_record_state
          end
        end
      end
    end
  end
end
