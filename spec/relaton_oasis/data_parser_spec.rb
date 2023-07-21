describe RelatonOasis::DataParser do
  let(:node) do
    Nokogiri::HTML File.read("spec/fixtures/amqp-v10.html", encoding: "UTF-8")
  end

  subject { RelatonOasis::DataParser.new(node.at("//details")) }

  it "parse" do
    bib = subject.parse
    xml = bib.to_xml bibdata: true
    file = "spec/fixtures/oasis_bibdata.xml"
    File.write file, xml, encoding: "UTF-8" unless File.exist? file
    expect(bib).to be_a RelatonOasis::OasisBibliographicItem
    expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
      .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}(?=<\/fetched>)/, Date.today.to_s)
  end

  it "parses title" do
    title = subject.parse_title
    expect(title).to be_a Array
    expect(title[0]).to be_a RelatonBib::TypedTitleString
    expect(title[0].type).to eq "main"
    expect(title[0].title.content).to eq "Advanced Message Queueing Protocol (AMQP) v1.0"
  end

  context "parses docid" do
    context "from parts" do
      it "when there is only one part" do
        doc = Nokogiri::HTML <<-EOHTML
          <details>
            <summary>
              <div class="standard__preview">
                <h2>Advanced Message Queueing Protocol (AMQP) v1.0</h2>
              </div>
            </summary>
            <div class="standard__details">
              <div class="standard__grid">
                <div class="standard__grid--cite-as">
                  <p><strong>[amqp-core-overview-v1.0]</strong></p>
                </div>
              </div>
            </div>
          </details>
        EOHTML
        parser = RelatonOasis::DataParser.new doc.at("//details")
        docid = parser.parse_docid
        expect(docid).to be_a Array
        expect(docid[0]).to be_a RelatonBib::DocumentIdentifier
        expect(docid[0].id).to eq "OASIS amqp-core-overview-v1.0"
        expect(docid[0].primary).to be true
      end

      it "OASIS Committee Specification" do
        doc = Nokogiri::HTML <<-EOHTML
          <details>
            <summary>
              <div class="standard__preview">
                <h2>Advanced Message Queuing Protocol (AMQP) Enforcing Connection Uniqueness Version 1.0</h2>
              </div>
            </summary>
            <div class="standard__details">
              <div class="standard__grid">
                <div class="standard__grid--cite-as">
                  <p>
                    <strong>[soleconn-v1.0]</strong>
                    <em>17 September 2018. OASIS Committee Specification 01. Latest version: </em>
                  </p>
                </div>
              </div>
            </div>
          </details>
        EOHTML
        parser = RelatonOasis::DataParser.new doc.at("//details")
        docid = parser.parse_docid
        expect(docid[0].id).to eq "OASIS soleconn-v1.0-CS01"
      end

      it "OASIS Project Specification" do
        doc = Nokogiri::HTML <<-EOHTML
          <details>
            <summary>
              <div class="standard__preview">
                <h2>OSLC Architecture Management Version 3.0 Project Specification 01</h2>
              </div>
            </summary>
            <div class="standard__details">
              <div class="standard__grid">
                <div class="standard__grid--cite-as">
                  <p>
                    <strong>[OSLC-AM-3.0-Part1]</strong>
                    <em>30 September 2021. OASIS Project Specification 01. Latest version: </em>
                  </p>
                </div>
              </div>
            </div>
          </details>
        EOHTML
        parser = RelatonOasis::DataParser.new doc.at("//details")
        docid = parser.parse_docid
        expect(docid[0].id).to eq "OASIS OSLC-AM-3.0-Part1-PS01"
      end

      it "when there are multiple parts" do
        doc = Nokogiri::HTML <<-EOHTML
          <details>
            <summary>
              <div class="standard__preview">
                <h2>Advanced Message Queueing Protocol (AMQP) v1.0</h2>
              </div>
            </summary>
            <div class="standard__details">
              <div class="standard__grid">
                <div class="standard__grid--cite-as">
                  <p><strong>[amqp-core-overview-v1.0]</strong></p>
                  <p><strong>[amqp-core-types-v1.0]</strong></p>
                </div>
              </div>
            </div>
          </details>
        EOHTML
        parser = RelatonOasis::DataParser.new doc.at("//details")
        docid = parser.parse_docid
        expect(docid[0].id).to eq "OASIS amqp-core"
      end

      context "from title" do
        it "with abbreviations in parentheses" do
          doc = Nokogiri::HTML <<-EOHTML
            <details>
              <summary>
                <div class="standard__peview">
                  <h2>Emergency Data Exchange Language (EDXL) Hospital AVailability Exchange (HAVE) Version 2.0</h2>
                </div>
              </summary>
            </details>
          EOHTML
          parser = RelatonOasis::DataParser.new doc.at("//details")
          dociid = parser.parse_docid
          expect(dociid[0].id).to eq "OASIS EDXL-HAVE-v2.0"
        end

        it "with abbreviations in text" do
          doc = Nokogiri::HTML <<-EOHTML
            <details>
              <summary>
                <div class="standard__peview">
                  <h2>Emergency Data Exchange Language EDXL Hospital AVailability Exchange HAVE Version 2.0</h2>
                </div>
              </summary>
            </details>
          EOHTML
          parser = RelatonOasis::DataParser.new doc.at("//details")
          dociid = parser.parse_docid
          expect(dociid[0].id).to eq "OASIS EDXL-HAVE-v2.0"
        end

        it "without abbreviations" do
          doc = Nokogiri::HTML <<-EOHTML
            <details>
              <summary>
                <div class="standard__preview">
                  <h2>ebXML Message Service Specification v2.0 [OASIS 200204]</h2>
                </div>
              </summary>
            </details>
          EOHTML
          parser = RelatonOasis::DataParser.new doc.at("//details")
          dociid = parser.parse_docid
          expect(dociid[0].id).to eq "OASIS ebXML-MSS-v2.0"
        end
      end
    end
  end

  it "parses date" do
    date = subject.parse_date
    expect(date).to be_a Array
    expect(date[0]).to be_a RelatonBib::BibliographicDate
    expect(date[0].on).to eq "2012-10-30"
    expect(date[0].type).to eq "issued"
  end

  it "parses abstract" do
    abstract = subject.parse_abstract
    expect(abstract).to be_a Array
    expect(abstract[0]).to be_a RelatonBib::FormattedString
    expect(abstract[0].content).to eq "An open internet protocol for business messaging."
    expect(abstract[0].format).to eq "text/plain"
    expect(abstract[0].language).to eq ["en"]
    expect(abstract[0].script).to eq ["Latn"]
  end

  it "parses editorialgroup" do
    ed = subject.parse_editorialgroup
    expect(ed).to be_a RelatonBib::EditorialGroup
    expect(ed.technical_committee).to be_a Array
    expect(ed.technical_committee[0]).to be_a RelatonBib::TechnicalCommittee
    expect(ed.technical_committee[0].workgroup).to be_a RelatonBib::WorkGroup
    expect(ed.technical_committee[0].workgroup.name).to eq "OASIS Advanced Message Queuing Protocol (AMQP) TC"
  end

  it "parses relation" do
    rel = subject.parse_relation
    expect(rel).to be_a Array
  end

  it "parses link" do
    html = File.read("spec/fixtures/mqtt-v50.html", encoding: "UTF-8")
    doc = Nokogiri::HTML(html).at("//details")
    dp = described_class.new doc
    link = dp.parse_link
    expect(link).to be_a Array
    expect(link.size).to eq 3
    expect(link[0]).to be_a RelatonBib::TypedUri
    expect(link[0].content.to_s).to eq "http://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html"
    expect(link[0].type).to eq "src"
    expect(link[1]).to be_a RelatonBib::TypedUri
    expect(link[1].content.to_s).to eq "http://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.pdf"
    expect(link[1].type).to eq "pdf"
    expect(link[2]).to be_a RelatonBib::TypedUri
    expect(link[2].content.to_s).to eq "http://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.docx"
    expect(link[2].type).to eq "doc"
  end

  it "parses document with multiple parts" do
    doc = Nokogiri::HTML File.read("spec/fixtures/odata-json-format-40.html", encoding: "UTF-8")
    dp = described_class.new doc.at("//details")
    bib = dp.parse
    expect(bib.docidentifier[0].id).to eq "OASIS OData-JSON-Format-v4.0"
  end
end
