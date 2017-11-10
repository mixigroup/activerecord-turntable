require 'spec_helper'

describe ActiveRecord::Turntable::Sequencer do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  before do
    establish_connection_to("test")
  end

  describe "#build" do
    context "when sequencer type mysql" do
      it "return ActiveRecord::Turntable::Sequencer::Mysql" do
        expect(ActiveRecord::Turntable::Sequencer.build(User)).to be_an_instance_of(ActiveRecord::Turntable::Sequencer::Mysql)
      end
    end

    context "when sequencer type redis" do
      it "return ActiveRecord::Turntable::Sequencer::Redis" do
        expect(ActiveRecord::Turntable::Sequencer.build(Friend)).to be_an_instance_of(ActiveRecord::Turntable::Sequencer::Redis)
      end
    end
  end
end
