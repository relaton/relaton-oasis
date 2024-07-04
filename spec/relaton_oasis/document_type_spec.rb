describe RelatonOasis::DocumentType do
  it "warns when document type is invalid" do
    expect do
      described_class.new type: "invalid"
    end.to output(/\[relaton-oasis\] WARN: invalid doctype: `invalid`/).to_stderr_from_any_process
  end
end
