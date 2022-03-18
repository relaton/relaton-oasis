describe RelatonOasis::DataPartParser do
  let(:doc) do
    Nokogiri::HTML <<-EOHTML
    <details>
      <summary>
        <div class="standard__preview">
          <h2>Advanced Message Queueing Protocol (AMQP) v1.0</h2>
          <time class="standard__date">01 Jan 2019</time>
          <div class="standard__description">
            <p>An open internet protocol for business messaging. </p>
            <ul class="technology-areas__list">
              <li class="technology-areas__item">
                <a href="http://www.oasis-open.org/filter">
                  Content Technologies
                </a>
              </li>
              <li class="technology-areas__item">
                <a href="http://www.oasis-open.org/filter">
                  eGov/Legal
                </a>
              </li>
            </ul>
          </div>
        </div>
      </summary>
      <div class="standard__details>
        <div class="standard__grid">
          <div class="standard__grid--cite-as">
            <p>
              <strong>[amqp-core-overview-v1.0]</strong>
              <span class="citationTitle">Title1</span>
              . Edited by Robert Godfrey, David Ingham, and Rafael Schloming. 29 October 2012. OASIS Standard.
              <a href="http://www.example.com/">Link</a>
            </p>
          </div>
        </div>
      </div>
    </details>
    EOHTML
  end

  subject { RelatonOasis::DataPartParser.new doc.at("//div[@class='standard__grid--cite-as']/p") }

  context "initialize" do
    it "with title in span" do
      doc = Nokogiri::HTML <<-EOHTML
        <p>
          <strong>[amqp-core-overview-v1.0]</strong>
          <span class="citationTitle">Title</span>
        </p>
      EOHTML
      parser = RelatonOasis::DataPartParser.new doc.at("//p")
      expect(parser.instance_variable_get(:@title)).to eq "Title"
    end

    it "with title as a text node" do
      doc = Nokogiri::HTML <<-EOHTML
        <p>
          <strong>[amqp-core-overview-v1.0]</strong>
          Title. Edited
        </p>
      EOHTML
      parser = RelatonOasis::DataPartParser.new doc.at("//p")
      expect(parser.instance_variable_get(:@title)).to eq "Title."
    end
  end

  it "parse" do
    expect(subject).to receive(:parse_doctype)
    expect(subject).to receive(:parse_docid)
    expect(subject).to receive(:parse_link)
    expect(subject).to receive(:parse_docnumber)
    expect(subject).to receive(:parse_date)
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
      expect(docid[0].id).to eq "OASIS amqp-core-overview-v1.0"
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
      expect(docid[0].id).to eq "OASIS BIASPROFILE-errata02"
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
      expect(docid[0].id).to eq "OASIS BIASPROFILE-plus-errata02"
    end
  end

  it "parse link" do
    link = subject.parse_link
    expect(link).to be_instance_of Array
    expect(link.size).to eq 1
    expect(link[0]).to be_instance_of RelatonBib::TypedUri
    expect(link[0].content.to_s).to eq "http://www.example.com/"
  end

  it "parse date" do
    date = subject.parse_date
    expect(date).to be_instance_of Array
    expect(date.size).to eq 1
    expect(date[0]).to be_instance_of RelatonBib::BibliographicDate
    expect(date[0].on).to eq "2012-10-29"
  end

  it "parse contributor" do
    contrib = subject.parse_contributor
    expect(contrib).to be_instance_of Array
    expect(contrib.size).to eq 3
    expect(contrib[0]).to be_instance_of RelatonBib::ContributionInfo
    expect(contrib[0].role).to be_instance_of Array
    expect(contrib[0].role.size).to eq 1
    expect(contrib[0].role[0]).to be_instance_of RelatonBib::ContributorRole
    expect(contrib[0].role[0].type).to eq "editor"
    expect(contrib[0].entity).to be_instance_of RelatonBib::Person
    expect(contrib[0].entity.name.forename).to be_instance_of Array
    expect(contrib[0].entity.name.forename.size).to eq 1
    expect(contrib[0].entity.name.forename[0]).to be_instance_of RelatonBib::LocalizedString
    expect(contrib[0].entity.name.forename[0].content).to eq "Robert"
    expect(contrib[0].entity.name.surname).to be_instance_of RelatonBib::LocalizedString
    expect(contrib[0].entity.name.surname.content).to eq "Godfrey"
  end

  it "parse relation" do
    rel = subject.parse_relation
    expect(rel).to be_instance_of Array
    expect(rel.size).to eq 1
    expect(rel[0]).to be_instance_of RelatonBib::DocumentRelation
    expect(rel[0].type).to eq "partOf"
    expect(rel[0].bibitem).to be_instance_of RelatonOasis::OasisBibliographicItem
    expect(rel[0].bibitem.formattedref).to be_instance_of RelatonBib::FormattedRef
    expect(rel[0].bibitem.formattedref.content).to eq "OASIS amqp-core-overview-v1.0"
  end

  it "parse techology area" do
    ta = subject.parse_technology_area
    expect(ta).to be_instance_of Array
    expect(ta.size).to eq 2
    expect(ta[0]).to eq "Content-Technologies"
    expect(ta[1]).to eq "eGov/Legal"
  end
end
