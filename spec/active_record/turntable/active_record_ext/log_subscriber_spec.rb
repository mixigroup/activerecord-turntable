require "spec_helper"

describe ActiveRecord::Turntable::ActiveRecordExt::LogSubscriber do
  REGEXP_MAGENTA = Regexp.escape(ActiveRecord::LogSubscriber::MAGENTA)
  REGEXP_CYAN = Regexp.escape(ActiveRecord::LogSubscriber::CYAN)
  if ActiveRecord::Turntable::Util.ar71_or_later?
    REGEXP_CLEAR = Regexp.escape("\e[#{ActiveRecord::LogSubscriber::MODES[:clear]}m")
  else
    REGEXP_CLEAR = Regexp.escape(ActiveRecord::LogSubscriber::CLEAR)
  end

  class TestLogSubscriber < ActiveRecord::LogSubscriber
    attr_reader :debugs

    def initialize
      @debugs = []
      super
    end

    def debug(message)
      @debugs << message
    end
  end

  TestEvent = Struct.new(:payload) do
    def sql
      "foo"
    end

    def duration
      0.7
    end
  end

  describe "#sql" do
    let(:subscriber) { TestLogSubscriber.new }

    it "ignore SCHEMA log" do
      expect(subscriber.debugs.length).to eq 0

      subscriber.sql(TestEvent.new({name: "bar", turntable_shard_name: "shard_1"}))
      expect(subscriber.debugs.length).to eq 1

      subscriber.sql(TestEvent.new({name: "SCHEMA", turntable_shard_name: "shard_1"}))
      expect(subscriber.debugs.length).to eq 1
    end

    context "When payload name is `SQL`" do
      it "logs in MAGENTA color" do
        subscriber.sql(TestEvent.new({name: "SQL", turntable_shard_name: "shard_1"}))
        expect(subscriber.debugs.first).to match(/#{REGEXP_MAGENTA}SQL \(0\.7ms\) \[Shard: shard_1\]#{REGEXP_CLEAR}/)
      end
    end

    context "When payload name is `Model Load`" do
      it "logs in CYAN color" do
        subscriber.sql(TestEvent.new({name: "Model Load", turntable_shard_name: "shard_1"}))
        expect(subscriber.debugs.first).to match(/#{REGEXP_CYAN}Model Load \(0\.7ms\) \[Shard: shard_1\]#{REGEXP_CLEAR}/)
      end
    end

    context "When payload includes `:binds` and `:type_casted_binds`" do
      it "logs binds parameters" do
        binds = [ActiveRecord::Relation::QueryAttribute.new("id", 10, ActiveRecord::Type::Value.new)]
        type_casted_binds = [10]
        subscriber.sql(TestEvent.new({name: "Model Load", binds: binds, type_casted_binds: type_casted_binds}))
        expect(subscriber.debugs.first).to match(/\[\["id", 10\]\]/)
      end
    end
  end
end
