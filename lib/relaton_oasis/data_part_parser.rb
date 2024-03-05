module RelatonOasis
  # Parser for OASIS part document.
  class DataPartParser
    include RelatonOasis::DataParserUtils

    #
    # Initialize parser.
    #
    # @param [Nokogiri::HTML::Element] node docment node
    #
    def initialize(node)
      @node = node
    end

    def text
      return @text if @text

      if @node.at("./strong/following-sibling::text()|./span[strong]/following-sibling::text()")
        @text = @node.xpath(
          "./strong/following-sibling::node()|./span[strong]/following-sibling::node()",
        ).text.strip
      else
        @text = @node.xpath("./following-sibling::p[1][em]").text.strip
      end
    end

    def title
      return @title if @title

      t = @node.at("./span[@class='citationTitle' or @class='citeTitle']|./em|./i")
      @title = if t then t.text
               else
                 text.match(/(?<content>.+)\s(?:Edited|\d{2}\s\w+\d{4})/)[:content]
               end.strip
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
        abstract: parse_abstract,
        language: ["en"],
        script: ["Latn"],
        editorialgroup: parse_editorialgroup,
        relation: parse_relation,
        contributor: parse_contributor,
        technology_area: parse_technology_area,
      )
    end

    #
    # Pase title.
    #
    # @return [Array<RelatonBib::TypedTitleString>] title
    #
    def parse_title
      [RelatonBib::TypedTitleString.new(type: "main", content: title, language: "en", script: "Latn")]
    end

    #
    # Parse document number.
    #
    # @return [String] document number
    #
    def parse_docnumber
      ref = @node.at("./span[@class='citationLabel']/strong|./strong|b/span")
      num = ref.text.match(/[^\[\]]+/).to_s
      id = parse_errata(num)
      # some part references need to be added by "Pt" to be distinguishable from root doc
      id += "-Pt" if %w[CMIS-v1.1 DocBook-5.0 XACML-V3.0 mqtt-v3.1.1 OData-JSON-Format-v4.0].include?(id)
      parse_part parse_spec id
    end

    #
    # Parse link.
    #
    # @return [Array<RelatonBib::TypedTitleString>] link
    #
    def parse_link
      [RelatonBib::TypedUri.new(type: "src", content: link_node[:href])]
    end

    #
    # Parse date.
    #
    # @return [Array<RelatonBib::BibliographicDate>] bibliographic dates
    #
    def parse_date
      /(?<on>\d{1,2}\s\w+\s\d{4})/ =~ text
      [RelatonBib::BibliographicDate.new(on: Date.parse(on).to_s, type: "issued")]
    end

    def parse_abstract
      page.xpath("//p[preceding-sibling::p[starts-with(., 'Abstract')]][1]").map do |p|
        cnt = p.text.gsub(/[\r\n]+/, " ").strip
        RelatonBib::FormattedString.new(content: cnt, language: "en", script: "Latn")
      end
    end

    #
    # Parse technical committee.
    #
    # @return [RelatonBib::EditorialGroup] technical committee
    #
    def parse_editorialgroup
      tc = page.xpath("//p[preceding-sibling::p[starts-with(., 'Technical')]][1]//a").map do |a|
        wg = RelatonBib::WorkGroup.new name: a.text.strip
        RelatonBib::TechnicalCommittee.new wg
      end
      RelatonBib::EditorialGroup.new tc
    end

    #
    # Parse relation.
    #
    # @return [Array<RelatonBib::DocumentRelation>] document relations
    #
    def parse_relation
      parser = DataParser.new @node.at("./ancestor::details")
      fref = RelatonBib::FormattedRef.new(content: parser.parse_docid[0].id)
      bib = RelatonOasis::OasisBibliographicItem.new(formattedref: fref)
      [RelatonBib::DocumentRelation.new(type: "partOf", bibitem: bib)]
    end

    def parse_authorizer
      return [] unless page

      page.xpath("//p[preceding-sibling::p[starts-with(., 'Technical')]][1]//a").map do |a|
        cnt = RelatonBib::Contact.new(type: "uri", value: a[:href])
        org = RelatonBib::Organization.new name: a.text.gsub(/[\r\n]+/, " ").strip, contact: [cnt]
        role = { type: "authorizer", description: ["Committee"] }
        RelatonBib::ContributionInfo.new entity: org, role: [role]
      end
    end

    def link_node
      @link_node = @node.at("./a|./following-sibling::p[1]/a")
    end

    #
    # Parse technology area.
    #
    # @return [Array<String>] technology areas
    #
    def parse_technology_area
      super @node.at("./ancestor::details")
    end
  end
end
