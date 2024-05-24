# -*- coding: utf-8 -*-
#
# 採番
#

module ActiveRecord::Turntable
  class Sequencer
    class Mysql < Sequencer
      def initialize(options = {})
        @options = options
        @shard = SeqShard.new(@options[:connection].to_s)
      end

      def connection
        @shard.connection
      end

      def release!
        @shard.connection_pool.release_connection
      end

       # mysql だけ offset を指定できるようにします
      def next_sequence_value(sequence_name, offset = 1)
        conn = connection
        conn.execute "UPDATE #{conn.quote_table_name(sequence_name)} SET id=LAST_INSERT_ID(id+#{offset})"
        new_id = last_insert_id(conn)
        raise SequenceNotFoundError if new_id.zero?
        new_id
      end

      def current_sequence_value(sequence_name)
        conn = connection
        conn.execute "UPDATE #{conn.quote_table_name(sequence_name)} SET id=LAST_INSERT_ID(id)"
        current_id = last_insert_id(conn)
        current_id
      end

      private

      def last_insert_id(conn)
        res = conn.execute("SELECT LAST_INSERT_ID()")
        if conn.adapter_name == "Trilogy"
          res.first.first.last.to_i
        else
          res.first.first.to_i
        end
      end
    end
  end
end
