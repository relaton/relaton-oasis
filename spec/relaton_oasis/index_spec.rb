describe RelatonOasis::Index do
  it "initialize" do
    expect(File).to receive(:exist?).with("index.yaml").and_return(false)
    expect(subject.instance_variable_get(:@file)).to eq "index.yaml"
    expect(subject.instance_variable_get(:@index)).to eq([])
  end

  context "fetch from GitHub" do
    let(:file) { File.join Dir.home, ".relaton", "oasis", "index.yaml" }

    it "when index file doesn't exist" do
      expect(File).to receive(:exist?).with(file).and_return(false)
      resp = {}.to_yaml
      expect(Net::HTTP).to receive(:get).and_return(resp)
      expect(File).to receive(:write).with(file, resp, encoding: "UTF-8")
      expect(described_class).to receive(:new).with(file).and_return(:index)
      expect(described_class.create_or_fetch).to eq :index
    end

    it "when index file is older than 24 hours" do
      expect(File).to receive(:exist?).with(file).and_return(true)
      expect(File).to receive(:ctime).with(file).and_return(Time.now - 86_400)
      expect(Net::HTTP).to receive(:get).and_return({}.to_yaml)
      expect(File).to receive(:write).with(file, {}.to_yaml, encoding: "UTF-8")
      expect(described_class).to receive(:new).with(file).and_return(:index)
      expect(described_class.create_or_fetch).to eq :index
    end

    it "index file doesn't exist on GitHub" do
      expect(File).to receive(:exist?).with(file).and_return(false)
      expect(Net::HTTP).to receive(:get).and_raise(StandardError, "error")
      expect(described_class.create_or_fetch).to be_nil
    end
  end

  context "instance methods" do
    it "put document's record to index" do
      fstring = double("FormattedString", content: "title")
      title = [double("title", title: fstring)]
      doc = double "doc", docidentifier: [double("id", id: "123")], title: title
      subject[doc] = "file"
      index = subject.instance_variable_get(:@index)
      expect(index).to eq [{ id: "123", title: "title", file: "file" }]
    end

    it "save index to file" do
      index = subject.instance_variable_get(:@index)
      index << { id: "123", title: "title", file: "file" }
      file = double "file"
      expect(file).to receive(:puts).with("---\n")
      expect(file).to receive(:puts).with("- id: '123'\n  title: 'title'\n  file: 'file'\n")
      expect(File).to receive(:open).with("index.yaml",
                                          "w:UTF-8").and_yield(file)
      subject.save
    end

    it "fetch document's record from index" do
      index = subject.instance_variable_get(:@index)
      index << { id: "123", title: "title", file: "file" }
      expect(subject["123"]).to eq({ id: "123", title: "title", file: "file" })
    end

    it "read from file" do
      expect(File).to receive(:exist?).with("index.yaml").and_return(false,
                                                                     true)
      expect(YAML).to receive(:load_file).with("index.yaml",
                                               symbolize_names: true)
        .and_return("index")
      subject.read
      expect(subject.instance_variable_get(:@index)).to eq "index"
    end
  end
end
