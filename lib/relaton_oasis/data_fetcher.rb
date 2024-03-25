module RelatonOasis
  class DataFetcher
    #
    # Initialize a new DataFetcher
    #
    # @param [Strin] output directory to save files, default: "data"
    # @param [Strin] format format of output files (xml, yaml, bibxml); default: yaml
    #
    def initialize(output, format)
      @output = output
      @format = format
      @ext = @format.sub(/^bib|^rfc/, "")
      @files = []
      @index = Index.new
      @index1 = Relaton::Index.find_or_create :oasis, file: "index-v1.yaml"
    end

    #
    # Initialize fetcher and run fetch
    #
    # @param [Strin] output directory to save files, default: "data"
    # @param [Strin] format format of output files (xml, yaml, bibxml); default: yaml
    #
    def self.fetch(output: "data", format: "yaml")
      t1 = Time.now
      puts "Started at: #{t1}"
      FileUtils.mkdir_p output
      new(output, format).fetch
      t2 = Time.now
      puts "Stopped at: #{t2}"
      puts "Done in: #{(t2 - t1).round} sec."
    end

    #
    # Fetch and save all the documents from OASIS
    #
    def fetch
      agent = Mechanize.new
      resp = agent.get "https://www.oasis-open.org/standards/"
      doc = Nokogiri::HTML resp.body
      doc.xpath("//details").map do |item|
        save_doc DataParser.new(item).parse
        fetch_parts item
      end
      @index.save
      @index1.save
    end

    #
    # Fetch and save parts of document
    #
    # @param [Nokogiri::HTML::Element] item document node
    #
    def fetch_parts(item)
      parts = item.xpath("./div/div/div[contains(@class, 'standard__grid--cite-as')]/p[strong or span/strong]")
      return unless parts.size > 1

      parts.each do |part|
        save_doc DataPartParser.new(part).parse
      end
    end

    #
    # Save document to file
    #
    # @param [RelatonOasis::OasisBibliographicItem] doc
    #
    def save_doc(doc) # rubocop:disable Metrics/MethodLength
      c = case @format
          when "xml" then doc.to_xml(bibdata: true)
          when "yaml" then doc.to_hash.to_yaml
          else doc.send("to_#{@format}")
          end
      file = file_name doc
      if @files.include? file
        Util.warn "File #{file} already exists. Document: #{doc.docnumber}"
      else
        @files << file
        @index[doc] = file
      end
      @index1.add_or_update doc.docnumber, file
      File.write file, c, encoding: "UTF-8"
    end

    #
    # Generate file name
    #
    # @param [RelatonOasis::OasisBibliographicItem] doc
    #
    # @return [String] file name
    #
    def file_name(doc)
      name = doc.docnumber.gsub(/[\s,:\/]/, "_").squeeze("_").upcase
      File.join @output, "#{name}.#{@ext}"
    end
  end
end
