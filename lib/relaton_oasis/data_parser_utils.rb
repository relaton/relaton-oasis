module RelatonOasis
  module DataParserUtils
    #
    # Parse document identifier specification.
    #
    # @param [String] num document number
    #
    # @return [String] document identifier with specification if needed
    #
    def parse_spec(num)
      id = case @text
           when /OASIS Project Specification (\d+)/ then "#{num}-PS#{$1}"
           when /Committee Specification (\d+)/ then "#{num}-CS#{$1}"
           else num
           end
      parse_part(id)
    end

    #
    # Parse document identifier part.
    #
    # @param [<Type>] docid <description>
    #
    # @return [<Type>] <description>
    #
    def parse_part(docid)
      return docid if docid.match?(/(?:Part|Pt)\d+/i)

      id = case @title
           when /Part\s(\d+)/ then "#{docid}-Pt#{$1}"
           else docid
           end
      parse_errata(id)
    end

    #
    # Parse document identifier errata.
    #
    # @param [String] id document identifier
    #
    # @return [String] document identifier with errata if needed
    #
    def parse_errata(id)
      return id if id.match?(/errata\d+/i)

      case @title
      when /Plus\sErrata\s(\d+)/ then "#{id}-plus-errata#{$1}"
      when /Errata\s(\d+)/ then "#{id}-errata#{$1}"
      else id
      end
    end

    #
    # Parse document identifier.
    #
    # @return [Array<RelatonBib::DocumentIdentifier>] document identifier
    #
    def parse_docid
      id = "OASIS #{parse_docnumber}"
      [RelatonBib::DocumentIdentifier.new(type: "OASIS", id: id, primary: true)]
    end

    #
    # Parse document type.
    #
    # @return [String] document type
    #
    def parse_doctype
      case @text
      when /OASIS Project Specification/, /Committee Specification/
        "specification"
      when /Technical Memorandum/ then "memorandum"
      when /Technical Resolution/ then "resolution"
      else "standard"
      end
    end

    #
    # Parse technology area.
    #
    # @return [Array<String>] technology areas
    #
    def parse_technology_area(node)
      node.xpath(
        "./summary/div/div/ul[@class='technology-areas__list']/li/a",
      ).map { |ta| ta.text.strip.gsub(/\s/, "-") }
    end
  end
end
