module RelatonOasis
  # Parser for OASIS document.
  class DataParser
    include RelatonOasis::DataParserUtils

    #
    # Initialize parser.
    #
    # @param [Nokogiri::HTML::Element] node docment node
    #
    def initialize(node)
      @node = node
    end

    def title
      @title ||= @node.at("./summary/div/h2").text
    end

    def text
      @text ||= @node.at(
        "./div/div/div[contains(@class, 'standard__grid--cite-as')]/p[em or i or a or span]",
      )&.text&.strip
    end

    #
    # Parse document.
    #
    # @return [RelatonOasis::OasisBibliographicItem] bibliographic item
    #
    def parse # rubocop:disable Metrics/MethodLength
      RelatonOasis::OasisBibliographicItem.new(
        type: "standard",
        doctype: parse_doctype,
        title: parse_title,
        docid: parse_docid,
        link: parse_link,
        docnumber: parse_docnumber,
        date: parse_date,
        contributor: parse_contributor,
        abstract: parse_abstract,
        language: ["en"],
        script: ["Latn"],
        editorialgroup: parse_editorialgroup,
        relation: parse_relation,
        technology_area: parse_technology_area,
      )
    end

    #
    # Parse title.
    #
    # @return [Array<RelatonBib::TypedTitleString>] <description>
    #
    def parse_title
      [RelatonBib::TypedTitleString.new(type: "main", content: title, language: "en", script: "Latn")]
    end

    #
    # Parse date.
    #
    # @return [Array<RelatonBib::BibliographicDate>] date
    #
    def parse_date
      @node.xpath("./summary/div/time[@class='standard__date']").map do |d|
        date_str = d.text.match(/\d{2}\s\w+\s\d{4}/).to_s
        date = Date.parse(date_str).to_s
        RelatonBib::BibliographicDate.new(on: date, type: "issued")
      end
    end

    # #
    # Parse abstract.
    #
    # @return [Array<RelatonBib::FormattedString>] abstract
    #
    def parse_abstract
      c = @node.xpath(
        "./summary/div/div[@class='standard__description']/p",
      ).map { |a| a.text.gsub(/[\n\t]+/, " ").strip }.join("\n")
      return [] if c.empty?

      [RelatonBib::FormattedString.new(content: c, language: "en", script: "Latn")]
    end

    #
    # Parse technical committee.
    #
    # @return [RelatonBib::EditorialGroup] technical committee
    #
    def parse_editorialgroup
      tc = @node.xpath("./div[@class='standard__details']/a").map do |a|
        wg = RelatonBib::WorkGroup.new name: a.text.strip
        RelatonBib::TechnicalCommittee.new wg
      end
      RelatonBib::EditorialGroup.new tc
    end

    def parse_authorizer
      @node.xpath("./div[@class='standard__details']/a").map do |a|
        cnt = RelatonBib::Contact.new(type: "uri", value: a[:href])
        org = RelatonBib::Organization.new name: a.text.strip, contact: [cnt]
        role = { type: "authorizer", description: ["Committee"] }
        RelatonBib::ContributionInfo.new entity: org, role: [role]
      end
    end

    def link_node
      @link_node ||= @node.at("./div/div/div[contains(@class, 'standard__grid--cite-as')]/p[strong or span/strong]/a")
    end

    #
    # Parse relation.
    #
    # @return [Array<RelatonBib::DocumentRelation>] relation
    #
    def parse_relation
      rels = @node.xpath(
        "./div/div/div[contains(@class, 'standard__grid--cite-as')]/p[strong or span/strong or b/span]",
      )
      return [] unless rels.size > 1

      rels.map do |r|
        docid = DataPartParser.new(r).parse_docid
        fref = RelatonBib::FormattedRef.new content: docid[0].id
        bib = RelatonOasis::OasisBibliographicItem.new formattedref: fref
        RelatonBib::DocumentRelation.new type: "hasPart", bibitem: bib
      end
    end

    #
    # Look for "Cite as" references.
    #
    # @return [Array<String>] document part references
    #
    def document_part_refs
      @node.css(
        ".standard__grid--cite-as > p > strong",
        "span.Refterm", "span.abbrev", "span.citationLabel > strong"
      ).map { |p| p.text.gsub(/^\[{1,2}|\]$/, "").strip }
    end

    def parse_link
      return [] if parts.size > 1

      links.map do |l|
        type = l[:href].match(/\.(\w+)$/)&.captures&.first
        type ||= "src"
        type.sub!("docx", "doc")
        type.sub!("html", "src")
        RelatonBib::TypedUri.new(type: type, content: l[:href])
      end
    end

    def parts
      @parts ||= @node.xpath(
        "./div/div/div[contains(@class, 'standard__grid--cite-as')]/p[strong or span/strong]",
      )
    end

    def links
      l = @node.xpath("./div/div/div[1]/p[1]/a[@href]")
      l = @node.xpath("./div/div/div[1]/p[2]/a[@href]") if l.empty?
      l
    end

    #
    # Parse document number.
    # If the docuemnt has no parts, the document number is constructed from the title.
    # If the document had one part, the document number is constructed from the part.
    # If the document has parts, the document number is constructed from the parts.
    #
    # @return [String] document number
    #
    def parse_docnumber
      parts = document_part_refs
      case parts.size
      when 0 then parse_spec title_to_docid(@node.at("./summary/div/h2").text)
      when 1 then parse_part parse_spec(parts[0])
      else parts_to_docid parts
      end
    end

    #
    # Create document identifier from parts references.
    #
    # @param [Array<String>] parts parts references
    #
    # @return [String] document identifier
    #
    def parts_to_docid(parts)
      id = parts[1..].each_with_object(parts[0].split("-")) do |part, acc|
        chunks = part.split "-"
        chunks.each.with_index do |chunk, idx|
          unless chunk.casecmp(acc[idx])&.zero?
            acc.slice!(idx..-1)
            break
          end
        end
      end.join("-")
      parse_part parse_spec(id)
    end

    #
    # Create document identifier from title.
    #
    # @param [String] title title
    #
    # @return [String] document identifier
    #
    def title_to_docid(title) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      abbrs = title.scan(/(?<=\()[^)]+(?=\))/)
      if abbrs.any?
        id = abbrs.map { |abbr| abbr.split.join("-") }.join "-"
        /(?:Version\s|v)(?<ver>[\d.]+)/ =~ title
        id += "-v#{ver}" if ver
        /(?<eb>ebXML|ebMS)/ =~ title
        id = "#{eb}-#{id}" if eb
        id
      else
        series_end = false
        title.sub(/\s\[OASIS\s\d+\]$/, "").split(/[,:]?\s|-|(?<=[a-z])(?=[A-Z][a-z])/)
          .each_with_object([""]) do |word, acc|
          if word =~ /^v[\d.]+/
            acc << $MATCH.to_s
            series_end = true
          elsif word.match?(/^Version/)
            acc << "v"
            series_end = false
          elsif word.match?(/^\d|ebXML|ebMS/)
            series_end ? acc << word : acc[-1] += word
            series_end = true
          elsif word.match?(/^\w+$/) && word == word.upcase
            series_end ? acc << word : acc[-1] = word
            series_end = true
          elsif word.match?(/[A-Z]+[a-z]+/)
            series_end ? acc << word[0] : acc[-1] += word[0]
            series_end = false
          end
        end.join "-"
      end
    end

    #
    # Parse technology areas.
    #
    # @return [Array<String>] technology areas
    #
    def parse_technology_area
      super @node
    end
  end
end
