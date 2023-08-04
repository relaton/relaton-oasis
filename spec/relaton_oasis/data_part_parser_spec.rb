describe RelatonOasis::DataPartParser do
  let(:doc) do
    Nokogiri::HTML File.read("spec/fixtures/amqp-v10.html", encoding: "UTF-8")
  end

  subject { RelatonOasis::DataPartParser.new doc.at("//div[contains(@class, 'standard__grid--cite-as')]/p") }

  context "#title" do
    it "with title in span" do
      doc = Nokogiri::HTML <<-EOHTML
        <p>
          <strong>[amqp-core-overview-v1.0]</strong>
          <span class="citationTitle">Title</span>
        </p>
      EOHTML
      parser = RelatonOasis::DataPartParser.new doc.at("//p")
      expect(parser.title).to eq "Title"
    end

    it "with title as a text node" do
      doc = Nokogiri::HTML <<-EOHTML
        <p>
          <strong>[amqp-core-overview-v1.0]</strong>
          Title. Edited
        </p>
      EOHTML
      parser = RelatonOasis::DataPartParser.new doc.at("//p")
      expect(parser.title).to eq "Title."
    end
  end

  it "parse" do
    expect(subject).to receive(:parse_doctype)
    expect(subject).to receive(:parse_docid)
    expect(subject).to receive(:parse_link)
    expect(subject).to receive(:parse_docnumber)
    expect(subject).to receive(:parse_date)
    expect(subject).to receive(:parse_abstract)
    expect(subject).to receive(:parse_editorialgroup)
    expect(subject).to receive(:parse_relation)
    expect(subject).to receive(:parse_contributor)
    expect(RelatonOasis::OasisBibliographicItem).to receive(:new)
    subject.parse
  end

  context "parse doctype" do
    it "when doctype is Specification" do
      doc = Nokogiri::HTML <<-EOHTML
        <p>
          <strong>[amqp-core-overview-v1.0]</strong>
          <i>Title</i>
          OASIS Project Specification
        </p>
      EOHTML
      parser = RelatonOasis::DataPartParser.new doc.at("//p")
      doctype = parser.parse_doctype
      expect(doctype).to eq "specification"
    end

    it "when doctype is Memorandum" do
      doc = Nokogiri::HTML <<-EOHTML
        <p>
          <strong>[amqp-core-overview-v1.0]</strong>
          <em>Title</em>
          OASIS Technical Memorandum
        </p>
      EOHTML
      parser = RelatonOasis::DataPartParser.new doc.at("//p")
      doctype = parser.parse_doctype
      expect(doctype).to eq "memorandum"
    end

    it "when doctype is Resolution" do
      doc = Nokogiri::HTML <<-EOHTML
        <p>
          <strong>[amqp-core-overview-v1.0]</strong>
          <em>Title</em>
          OASIS Technical Resolution
        </p>
      EOHTML
      parser = RelatonOasis::DataPartParser.new doc.at("//p")
      doctype = parser.parse_doctype
      expect(doctype).to eq "resolution"
    end

    it "when doctype is not present" do
      doctype = subject.parse_doctype
      expect(doctype).to eq "standard"
    end
  end

  context "parse docid" do
    it "without errata" do
      docid = subject.parse_docid
      expect(docid).to be_instance_of Array
      expect(docid[0]).to be_instance_of RelatonBib::DocumentIdentifier
      expect(docid[0].id).to eq "OASIS amqp-core-overview-v1.0-Pt0"
      expect(docid[0].type).to eq "OASIS"
      expect(docid[0].primary).to be true
    end

    it "with errata" do
      doc = Nokogiri::HTML <<-EOHTML
      <p>
        <strong>[BIASPROFILE]</strong>
        <em>Biometric Identity Assurance Services (BIAS) SOAP Profile Version 1.0 Errata 02</em>
      </p>
      EOHTML
      parser = RelatonOasis::DataPartParser.new doc.at("//p")
      docid = parser.parse_docid
      expect(docid[0].id).to eq "OASIS BIASPROFILE-Errata02"
    end

    it "plus errata" do
      doc = Nokogiri::HTML <<-EOHTML
      <p>
        <strong>[BIASPROFILE]</strong>
        <em>Biometric Identity Assurance Services (BIAS) SOAP Profile Version 1.0 Plus Errata 02</em>
      </p>
      EOHTML
      parser = RelatonOasis::DataPartParser.new doc.at("//p")
      docid = parser.parse_docid
      expect(docid[0].id).to eq "OASIS BIASPROFILE-plus-Errata02"
    end
  end

  it "parse link" do
    link = subject.parse_link
    expect(link).to be_instance_of Array
    expect(link.size).to eq 1
    expect(link[0]).to be_instance_of RelatonBib::TypedUri
    expect(link[0].content.to_s).to eq "http://docs.oasis-open.org/amqp/core/v1.0/os/amqp-core-overview-v1.0-os.html"
  end

  it "parse date" do
    date = subject.parse_date
    expect(date).to be_instance_of Array
    expect(date.size).to eq 1
    expect(date[0]).to be_instance_of RelatonBib::BibliographicDate
    expect(date[0].on).to eq "2012-10-29"
  end

  it "#parse_authorizer", vcr: "part_editors" do
    contrib = subject.parse_authorizer
    expect(contrib).to be_instance_of Array
    expect(contrib.size).to eq 1
    expect(contrib[0]).to be_instance_of RelatonBib::ContributionInfo
    expect(contrib[0].role).to be_instance_of Array
    expect(contrib[0].role.size).to eq 1
    expect(contrib[0].role[0].type).to eq "authorizer"
    expect(contrib[0].role[0].description).to be_instance_of Array
    expect(contrib[0].role[0].description.size).to eq 1
    expect(contrib[0].role[0].description[0].content).to eq "Committee"
    expect(contrib[0].entity).to be_instance_of RelatonBib::Organization
    expect(contrib[0].entity.name).to be_instance_of Array
    expect(contrib[0].entity.name.size).to eq 1
    expect(contrib[0].entity.name[0].content).to eq "OASIS Advanced Message Queuing Protocol (AMQP) TC"
    expect(contrib[0].entity.contact).to be_instance_of Array
    expect(contrib[0].entity.contact.size).to eq 1
    expect(contrib[0].entity.contact[0]).to be_instance_of RelatonBib::Contact
    expect(contrib[0].entity.contact[0].type).to eq "uri"
    expect(contrib[0].entity.contact[0].value).to eq "http://www.oasis-open.org/committees/amqp/"
  end

  it "parse relation" do
    rel = subject.parse_relation
    expect(rel).to be_instance_of Array
    expect(rel.size).to eq 1
    expect(rel[0]).to be_instance_of RelatonBib::DocumentRelation
    expect(rel[0].type).to eq "partOf"
    expect(rel[0].bibitem).to be_instance_of RelatonOasis::OasisBibliographicItem
    expect(rel[0].bibitem.formattedref).to be_instance_of RelatonBib::FormattedRef
    expect(rel[0].bibitem.formattedref.content).to eq "OASIS amqp-core"
  end

  it "parse techology area" do
    ta = subject.parse_technology_area
    expect(ta).to be_instance_of Array
    expect(ta.size).to eq 1
    expect(ta[0]).to eq "Messaging"
  end

  context "parse parts" do
    let(:doc) do
      html = File.read "spec/fixtures/odata-json-format-40.html", encoding: "UTF-8"
      Nokogiri::HTML(html).at("//details")
    end

    it "", vcr: "odata-json-format-40-parts" do
      parts = doc.xpath("./div/div/div[contains(@class, 'standard__grid--cite-as')]" \
                        "/p[strong or span/strong]").map do |part|
        described_class.new(part).parse
      end
      expect(parts.size).to eq 5
      expect(parts[0].docidentifier[0].id).to eq "OASIS OData-JSON-Format-v4.0-Pt"
      expect(parts[1].docidentifier[0].id).to eq "OASIS OData-JSON-Format-v4.0-plus-Errata01"
      expect(parts[2].docidentifier[0].id).to eq "OASIS OData-JSON-Format-v4.0-plus-Errata02"
      expect(parts[3].docidentifier[0].id).to eq "OASIS OData-JSON-Format-v4.0-Errata03"
      expect(parts[4].docidentifier[0].id).to eq "OASIS OData-JSON-Format-v4.0-plus-Errata03"
    end
  end

  it "#parse_editorialgroup", vcr: "amqp-v10" do
    eg = subject.parse_editorialgroup
    expect(eg).to be_instance_of RelatonBib::EditorialGroup
    expect(eg.technical_committee).to be_instance_of Array
    expect(eg.technical_committee.size).to eq 1
    expect(eg.technical_committee[0]).to be_instance_of RelatonBib::TechnicalCommittee
    expect(eg.technical_committee[0].workgroup).to be_instance_of RelatonBib::WorkGroup
    expect(eg.technical_committee[0].workgroup.name).to eq "OASIS Advanced Message Queuing Protocol (AMQP) TC"
  end

  it "#parse_abstract", vcr: "amqp-v10" do
    abs = subject.parse_abstract
    expect(abs).to be_instance_of Array
    expect(abs.size).to eq 1
    expect(abs[0]).to be_instance_of RelatonBib::FormattedString
    expect(abs[0].content).to match(/The Advanced Message Queuing Protocol/)
    expect(abs[0].language).to eq ["en"]
    expect(abs[0].script).to eq ["Latn"]
  end
end
