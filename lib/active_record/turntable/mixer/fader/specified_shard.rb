module ActiveRecord::Turntable
  class Mixer
    class Fader
      class SpecifiedShard < Fader
        def execute
          shard, query = @shards_query_hash.first
          @proxy.with_shard(shard) do
            args = @args.dup
            last_arg = @args.last.is_a?(Hash) ? args.pop : {}
            shard.connection.send(@called_method, query, *args, **last_arg, &@block)
          end
        end
      end
    end
  end
end
