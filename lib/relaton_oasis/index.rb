module RelatonOasis
  # Index of OASIS documents.
  class Index
    #
    # Initialize a new Index
    #
    def initialize(file = "index.yaml")
      @file = file
      read
    end

    #
    # Read index from file or fetch from GitHub.
    #
    # @return [RelatonOasis::Index, nil] index
    #
    def self.create_or_fetch
      file = File.join Dir.home, ".relaton", "oasis", "index.yaml"
      unless File.exist?(file) && File.ctime(file) > Time.now - 86_400
        url = "https://raw.githubusercontent.com/relaton/relaton-data-oasis/main/index.yaml"
        idx = Net::HTTP.get URI url
        File.write file, idx, encoding: "UTF-8"
      end
      new file
    rescue StandardError => e
      Util.error "Failed to fetch index: #{e.message}"
    end

    #
    # Put document's record to index.
    #
    # @param [RelatonOasis::OasisBibliographicItem] doc document
    # @param [String] file file name
    #
    def []=(doc, file) # rubocop:disable Metrics/AbcSize
      rec = self[doc.docidentifier[0].id]
      rec ||= begin
        @index << { id: doc.docidentifier[0].id }
        @index.last
      end
      rec[:title] = doc.title[0].title.content
      rec[:file] = file
    end

    #
    # Fetch document's record from index.
    #
    # @param [String] id document identifier
    #
    # @return [Hash] document's record
    #
    def [](id)
      @index.detect { |i| i[:id] == id }
    end

    #
    # Save index to file.
    #
    def save
      File.open @file, "w:UTF-8" do |f|
        f.puts "---\n"
        @index.each do |i|
          f.puts "- id: '#{i[:id]}'\n  title: '#{i[:title]}'\n  file: '#{i[:file]}'\n"
        end
      end
    end

    #
    # Read from file or create empty index.
    #
    def read
      @index = if File.exist?(@file)
                 YAML.load_file(@file,
                                symbolize_names: true)
               else
                 []
               end
    end
  end
end
