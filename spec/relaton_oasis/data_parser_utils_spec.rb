describe RelatonOasis::DataParserUtils do
  let(:utils) { Class.new { include RelatonOasis::DataParserUtils } }
  subject { utils.new }

  it "#retry_page" do
    agent = double("agent")
    expect(agent).to receive(:get).with(:url).and_raise(Errno::ETIMEDOUT).exactly(3).times
    expect(subject).to receive(:sleep).with(1).exactly(3).times
    expect do
      expect(subject.retry_page(:url, agent)).to be_nil
    end.to output(/Failed to get page `url`/).to_stderr_from_any_process
  end
end
