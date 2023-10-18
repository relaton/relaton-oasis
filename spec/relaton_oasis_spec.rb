# frozen_string_literal: true

RSpec.describe RelatonOasis do
  before { RelatonOasis.instance_variable_set :@configuration, nil }

  it "has a version number" do
    expect(RelatonOasis::VERSION).not_to be nil
  end

  it "retur grammar hash" do
    hash = RelatonOasis.grammar_hash
    expect(hash).to be_instance_of String
    expect(hash.size).to eq 32
  end

  it "get document", vcr: "oasis_bib" do
    expect do
      item = RelatonOasis::OasisBibliography.get "OASIS AkomaNtosoCore-v1.0-Pt1-Vocabulary"
      xml = item.to_xml(bibdata: true)
      file = "spec/fixtures/document.xml"
      File.write file, xml, encoding: "UTF-8" unless File.exist? file
      expect(item).to be_instance_of RelatonOasis::OasisBibliographicItem
      expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
        .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}(?=<\/fetched>)/, Date.today.to_s)
      schema = Jing.new "grammars/relaton-oasis-compile.rng"
      errors = schema.validate file
      expect(errors).to eq []
    end.to output(
      include("Fetching from Relaton repository",
              "Found: `OASIS AkomaNtosoCore-v1.0-Pt1-Vocabulary`"),
    ).to_stderr
  end

  it "not found" do
    expect do
      resp = RelatonOasis::OasisBibliography.get "invalid"
      expect(resp).to be_nil
    end.to output(/\[relaton-oasis\] \(invalid\) Not found\./).to_stderr
  end
end
