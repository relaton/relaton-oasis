describe RelatonOasis::DataFetcher do
  # it do
  #   VCR.use_cassette "oasis_data_fetcher" do
  #     RelatonOasis::DataFetcher.fetch
  #   end
  # end

  subject { RelatonOasis::DataFetcher.new "data", "yaml" }

  it "initialize" do
    expect(subject.instance_variable_get(:@files)).to be_a Array
  end

  it "create output dir and run fetcher" do
    expect(FileUtils).to receive(:mkdir_p).with("dir")
    fetcher = double("fetcher")
    expect(fetcher).to receive(:fetch)
    expect(RelatonOasis::DataFetcher)
      .to receive(:new).with("dir", "xml").and_return(fetcher)
    RelatonOasis::DataFetcher.fetch output: "dir", format: "xml"
  end

  it "fetch" do
    agent = double "agent"
    resp = double "resp", body: <<~EOHTML
      <details>
        <div><div><div class="standard__grid--cite-as">
          <p><strong>[ref1]</strong></p>
          <p><span><strong>[ref2]</strong></span></p>
        </div></div></div>
      </details>
    EOHTML
    expect(agent).to receive(:get).with("https://www.oasis-open.org/standards/").and_return(resp)
    expect(Mechanize).to receive(:new).and_return(agent)
    parser = double "parser"
    expect(parser).to receive(:parse).and_return(:bibitem)
    expect(subject).to receive(:save_doc).with(:bibitem).exactly(3).times
    expect(RelatonOasis::DataParser).to receive(:new).with(kind_of(Nokogiri::XML::Element)).and_return(parser)
    part_parser = double "part_parser"
    expect(part_parser).to receive(:parse).and_return(:bibitem).twice
    expect(RelatonOasis::DataPartParser).to receive(:new).with(kind_of(Nokogiri::XML::Element)).and_return(part_parser).twice
    expect(subject.instance_variable_get(:@index)).to receive(:save)
    expect(subject.instance_variable_get(:@index1)).to receive(:save)
    subject.fetch
  end

  context "save doc" do
    let(:doc) { double "doc", docnumber: "docnumber" }
    let(:index) { subject.instance_variable_get(:@index) }
    let(:index1) { subject.instance_variable_get(:@index1) }

    before do
      expect(subject).to receive(:file_name).with(doc).and_return("file")
    end

    it "xml" do
      subject.instance_variable_set :@format, "xml"
      expect(doc).to receive(:to_xml).with(bibdata: true).and_return("<xml/>")
      expect(index).to receive(:[]=).with(doc, "file")
      expect(index1).to receive(:add_or_update).with("docnumber", "file")
      expect(File).to receive(:write).with("file", "<xml/>", encoding: "UTF-8")
      subject.save_doc doc
      files = subject.instance_variable_get(:@files)
      expect(files).to include "file"
    end

    it "yaml" do
      expect(doc).to receive(:to_hash).and_return(:hash)
      expect(index).to receive(:[]=).with(doc, "file")
      expect(index1).to receive(:add_or_update).with("docnumber", "file")
      expect(File).to receive(:write).with("file", :hash.to_yaml, encoding: "UTF-8")
      subject.save_doc doc
    end

    it "bibxml" do
      subject.instance_variable_set :@format, "bibxml"
      expect(doc).to receive(:to_bibxml).and_return("<xml/>")
      expect(index).to receive(:[]=).with(doc, "file")
      expect(index1).to receive(:add_or_update).with("docnumber", "file")
      expect(File).to receive(:write).with("file", "<xml/>", encoding: "UTF-8")
      subject.save_doc doc
    end

    it "duplicate file warn" do
      subject.instance_variable_get(:@files) << "file"
      expect(doc).to receive(:to_hash).and_return(:hash)
      expect(File).to receive(:write).with("file", :hash.to_yaml, encoding: "UTF-8")
      expect(index1).to receive(:add_or_update).with("docnumber", "file")
      expect do
        subject.save_doc doc
      end.to output(/File file already exists/).to_stderr
    end
  end

  it "filename" do
    doc = double "doc", docnumber: "docnumber"
    expect(subject.file_name(doc)).to eq "data/DOCNUMBER.yaml"
  end
end
