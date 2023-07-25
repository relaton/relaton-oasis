module RelatonOasis
  # Common methods for document and part parsers.
  module DataParserUtils
    #
    # Parse contributor.
    #
    # @return [Array<RelatonBib::ContributionInfo>] contributors
    #
    def parse_contributor
      return [] unless text

      text.match(/(?<=Edited\sby\s)[^.]+/).to_s.split(/,?\sand\s|,\s/).map do |c|
        RelatonBib::ContributionInfo.new(role: [type: "editor"], entity: create_person(c))
      end
    end

    def parse_editors
      link = @node.at("./div/div/div[contains(@class, 'standard__grid--cite-as')]/p[strong or span/strong]/a")
      link ||= @node.at("./a")
      return parse_contributor unless link && link[:href].match?(/\.html$/)

      agent = Mechanize.new
      agent.agent.allowed_error_codes = [404]
      sleep 1 # to avoid 429 error
      page = agent.get link[:href]
      return parse_contributor unless page.code == "200"

      page.xpath("//p[contains(@class, 'Contributor') and preceding-sibling::p[contains(., 'Editor')]]").map do |p|
        name = p.text.match(/^[^(]+/).to_s.strip
        email, org = p.xpath ".//a[@href]"
        entity = create_person name, email, org
        RelatonBib::ContributionInfo.new(role: [type: "editor"], entity: entity)
      end
    end

    def create_person(name, email = nil, org = nil)
      forename, surname = name.split
      fn = RelatonBib::Forename.new(content: forename, language: ["en"], script: ["Latn"])
      sn = RelatonBib::LocalizedString.new(surname, "en", "Latn")
      name = RelatonBib::FullName.new(surname: sn, forename: [fn])
      RelatonBib::Person.new(name: name, contact: contact(email), affiliation: affiliation(org))
    end

    def contact(email)
      return [] unless email

      [RelatonBib::Contact.new(type: "email", value: email[:href].split(":")[1])]
    end

    def affiliation(org)
      return [] unless org

      cnt = RelatonBib::Contact.new(type: "url", value: org[:href])
      org_name = org.text.gsub(/[\r\n]+/, " ")
      organization = RelatonBib::Organization.new name: org_name, contact: [cnt]
      [RelatonBib::Affiliation.new(organization: organization)]
    end

    #
    # Parse document identifier specification.
    #
    # @param [String] num document number
    #
    # @return [String] document identifier with specification if needed
    #
    def parse_spec(num)
      id = case text
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

      case title
      when /Part\s(\d+)/ then "#{docid}-Pt#{$1}"
      else docid
      end
    end

    #
    # Parse document identifier errata.
    #
    # @param [String] id document identifier
    #
    # @return [String] document identifier with errata if needed
    #
    def parse_errata(id)
      return id.sub("errata", "Errata") if id.match?(/errata\d+/i)

      case title
      when /Plus\sErrata\s(\d+)/ then "#{id}-plus-Errata#{$1}"
      when /Errata\s(\d+)/ then "#{id}-Errata#{$1}"
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
      case text
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
