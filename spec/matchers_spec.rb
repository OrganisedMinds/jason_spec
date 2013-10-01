require "spec_helper"

describe Jason::Matchers do
  let(:fake_rspec) do
    fake = Class.new
    fake.send(:include, Jason::Matchers)
    fake.new
  end

  it "provides have_jason in rspec space" do
    fake_rspec.should be_respond_to(:have_jason)
  end

  it "should return instantiate a Jason::Spec" do
    spec = { type: Array }
    Jason::HaveJasonMatcher.should_receive(:new).with(spec)
    fake_rspec.have_jason(spec)
  end

  it "should return a Jason::Spec" do
    fake_rspec.have_jason({}).should be_is_a(Jason::HaveJasonMatcher)
  end
end
