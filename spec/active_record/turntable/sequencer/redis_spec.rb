require 'spec_helper'
require 'redis'

describe ActiveRecord::Turntable::Sequencer::Redis do
  let (:sequencer) { ActiveRecord::Turntable::Sequencer::Redis.new(Object, {host: "127.0.0.1"})}
  let (:sequencer_name) { "test_sequencer" }

  context "exists sequencer key" do
    before do
      client = Redis.new(host: "127.0.0.1")
      client.set(sequencer_name, 100)
    end

    describe "#next_sequence_value" do
      context "when use default offset" do
        it "return 101" do
          expect(sequencer.next_sequence_value(sequencer_name)).to eq 101
        end
      end
      context "when offset 100" do
        it "return 200" do
          expect(sequencer.next_sequence_value(sequencer_name, 100)).to eq 200
        end
      end
    end

    describe "#current_sequence_value" do
      it do
        expect(sequencer.current_sequence_value(sequencer_name)).to eq 100
      end
    end
  end

  context "not exists sequencer key" do
    before do
      client = Redis.new(host: "127.0.0.1")
      client.del(sequencer_name)
    end

    describe "#next_sequence_value" do
      it "raise ActiveRecord::Turntable::SequenceNotFoundError" do
        expect { sequencer.next_sequence_value(sequencer_name) }.to raise_error(ActiveRecord::Turntable::SequenceNotFoundError)
      end
    end

    describe "#current_sequence_value" do
      it "raise ActiveRecord::Turntable::SequenceNotFoundError" do
        expect { sequencer.current_sequence_value(sequencer_name) }.to raise_error(ActiveRecord::Turntable::SequenceNotFoundError)
      end
    end
  end

  context "sequencer value is not number" do
    before do
      client = Redis.new(host: "127.0.0.1")
      client.set(sequencer_name, "abc")
    end

    describe "#next_sequence_value" do
      it "raise Redis::CommandError" do
        expect { sequencer.next_sequence_value(sequencer_name) }.to raise_error(Redis::CommandError)
      end
    end

    describe "#current_sequence_value" do
      it "raise ActiveRecord::Turntable::SequenceValueBrokenError" do
        expect { sequencer.current_sequence_value(sequencer_name) }.to raise_error(ActiveRecord::Turntable::SequenceValueBrokenError)
      end
    end
  end
end
