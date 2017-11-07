# -*- coding: utf-8 -*-
#
# redisを利用しての採番
#
module ActiveRecord::Turntable
  class Sequencer
    class Redis < Sequencer
      @@clients = {}

      def initialize(klass, options = {})
        require "redis"
        @klass = klass
        @option = options
      end

      def next_sequence_value(sequence_name, offset = 1)
        id = client.evalsha(lua_script_sha, argv: [sequence_name, offset] )
        raise SequenceNotFoundError if id.nil?
        return id
      end

      def current_sequence_value(sequence_name)
        id = client.get(sequence_name)
        raise SequenceNotFoundError if id.nil?
        return id
      end

      private

      def client
        @@clients[@option] ||= ::Redis.new(@option)
      end

      def lua_script_sha
        @lua ||= client.script(:load, "return redis.call('EXISTS', ARGV[1]) == 1 and redis.call('INCRBY', ARGV[1], ARGV[2]) or nil")
      end
    end
  end
end

