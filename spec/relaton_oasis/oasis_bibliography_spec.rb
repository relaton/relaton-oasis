describe RelatonOasis::OasisBibliography do
  it "raise error" do
    index = double "index"
    expect(index).to receive(:search).and_return [{ id: "ret", file: "file" }]
    expect(Relaton::Index).to receive(:find_or_create).and_return index
    agent = double "agent"
    expect(agent).to receive(:get).and_raise Mechanize::ResponseCodeError.new(Mechanize::Page.new)
    expect(Mechanize).to receive(:new).and_return agent
    expect do
      RelatonOasis::OasisBibliography.get "ref"
    end.to raise_error RelatonBib::RequestError
  end
end
