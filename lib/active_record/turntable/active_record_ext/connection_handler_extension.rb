module ActiveRecord::Turntable
  module ActiveRecordExt
    module ConnectionHandlerExtension
      def owner_to_turntable_pool
        @owner_to_turntable_pool ||= Concurrent::Map.new(initial_capacity: 2)
      end

      if Util.ar_version_equals_or_later?("6.1.0")
        def retrieve_connection_pool(spec_name, role: ActiveRecord::Base.current_role, shard: ActiveRecord::Base.current_shard)
          owner_to_turntable_pool.fetch(spec_name) do
            super
          end
        end
      else
        # @note Override not to establish_connection destroy existing connection pool proxy object
        def retrieve_connection_pool(spec_name)
          owner_to_turntable_pool.fetch(spec_name) do
            super
          end
        end
      end
    end
  end
end
