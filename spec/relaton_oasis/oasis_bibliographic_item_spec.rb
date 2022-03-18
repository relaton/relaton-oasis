describe RelatonOasis::OasisBibliographicItem do
  subject do
    xml = File.read "spec/fixtures/oasis_bibdata.xml", encoding: "UTF-8"
    RelatonOasis::XMLParser.from_xml xml
  end

  it "warns when technology area is invalid" do
    expect do
      RelatonOasis::OasisBibliographicItem.new(technology_area: ["invalid"])
    end.to output(/Unknown technology area: invalid/).to_stderr
  end

  it "render hash" do
    hash = subject.to_hash
    file = "spec/fixtures/oasis_bibdata.yaml"
    File.write file, hash.to_yaml, encoding: "UTF-8" unless File.exist? file
    expect(hash).to eq YAML.safe_load File.read(file, encoding: "UTF-8")
  end

  it "render asciibib" do
    abib = subject.to_asciibib
    file = "spec/fixtures/oasis_bibdata.adoc"
    File.write file, abib, encoding: "UTF-8" unless File.exist? file
    expect(abib).to eq File.read(file, encoding: "UTF-8")
  end

  it "parse YAML" do
    file = "spec/fixtures/oasis_bibdata.yaml"
    hash = YAML.safe_load File.read(file, encoding: "UTF-8")
    bib = RelatonOasis::OasisBibliographicItem.from_hash hash
    expect(bib.to_hash).to eq hash
  end
end
