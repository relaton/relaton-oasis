# frozen_string_literal: true

RSpec.describe RelatonOasis do
  it "has a version number" do
    expect(RelatonOasis::VERSION).not_to be nil
  end

  it "retur grammar hash" do
    hash = RelatonOasis.grammar_hash
    expect(hash).to be_instance_of String
    expect(hash.size).to eq 32
  end

  it "get document" do
    VCR.use_cassette "oasis_bib" do
      item = RelatonOasis::OasisBibliography.get "AkomaNtosoCore-v1.0-Pt1-Vocabulary"
      xml = item.to_xml bibdata: true
      file = "spec/fixtures/document.xml"
      File.write file, xml, encoding: "UTF-8" unless File.exist? file
      expect(item).to be_instance_of RelatonOasis::OasisBibliographicItem
      xml.gsub!(/<fetched>[\d-]+<\/fetched>/, "")
      expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
        .gsub(/<fetched>[\d-]+<\/fetched>/, "")
    end
  end

  it "not found" do
    VCR.use_cassette "oasis_bib_not_found" do
      expect do
        resp = RelatonOasis::OasisBibliography.get "invalid"
        expect(resp).to be_nil
      end.to output(/not found/).to_stderr
    end
  end
end
