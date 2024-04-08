require "spec_helper"

describe ActiveRecord::Turntable::ActiveRecordExt::LockingOptimistic do
  around do |example|
    ActiveRecord::Base.turntable_configuration.raise_on_not_specified_shard_update = true
    example.run
    ActiveRecord::Base.turntable_configuration.raise_on_not_specified_shard_update = false
  end

  let(:user) { create(:user) }
  let(:user_profile) { user.user_profile }

  describe "optimistic locking" do
    if ActiveRecord::Turntable::Util.ar60_or_later?
      subject { user_profile.update(birthday: Date.current) }
    else
      subject { user_profile.update_attributes(birthday: Date.current) }
    end

    it { expect { subject }.to change(user_profile, :lock_version).by(1) }
  end

  describe "Json serialized column is saved" do
    before do
      user_profile.update_attributes(data: { foo: "bar" })
      user_profile.reload
    end

    subject { user_profile.data }

    it { expect { subject }.not_to raise_error }
  end
end
