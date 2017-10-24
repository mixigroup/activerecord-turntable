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
        client.incrby(sequence_name, offset)
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
    end
  end
end
