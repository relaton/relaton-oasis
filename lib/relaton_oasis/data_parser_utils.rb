module RelatonOasis
  # Common methods for document and part parsers.
  module DataParserUtils
    #
    # Parse contributor.
    #
    # @return [Array<RelatonBib::ContributionInfo>] contributors
    #
    def parse_contributor
      publisher_oasis + parse_authorizer + parse_chairs + parse_editors
    end

    def publisher_oasis
      cnt = RelatonBib::Contact.new type: "uri", value: "https://www.oasis-open.org/"
      entity = RelatonBib::Organization.new name: "OASIS", contact: [cnt]
      role = [
        { type: "authorizer", description: ["Standards Development Organization"] },
        { type: "publisher" },
      ]
      [RelatonBib::ContributionInfo.new(entity: entity, role: role)]
    end

    def parse_editors_from_text
      return [] unless text

      text.match(/(?<=Edited\sby\s)[^.]+/).to_s.split(/,?\sand\s|,\s/).map do |c|
        RelatonBib::ContributionInfo.new(role: [type: "editor"], entity: create_person(c))
      end
    end

    def page
      return @page if defined? @page

      if link_node && link_node[:href].match?(/\.html$/)
        agent = Mechanize.new
        agent.agent.allowed_error_codes = [404]
        resp = retry_page(link_node[:href], agent)
        @page = resp if resp && resp.code == "200"
      end
    end

    #
    # Retry to get page.
    #
    # @param [String] url page URL
    # @param [Mechanize] agent HTTP client
    # @param [Integer] retries number of retries
    #
    # @return [Mechanize::Page, nil] page or nil
    #
    def retry_page(url, agent, retries = 3)
      sleep 1 # to avoid 429 error
      agent.get url
    rescue Errno::ETIMEDOUT, Net::OpenTimeout => e
      retry if (retries -= 1).positive?
      Util.error "Failed to get page `#{url}`\n#{e.message}"
      nil
    end

    def parse_chairs
      return [] unless page

      page.xpath(
        "//p[preceding-sibling::p[starts-with(., 'Chair')]][following-sibling::p[starts-with(., 'Editor')]]",
      ).map { |p| create_contribution_info(p, "editor", ["Chair"]) }
    end

    def parse_editors
      return parse_editors_from_text unless page

      page.xpath(
        "//p[contains(@class, 'Contributor')][preceding-sibling::p[starts-with(., 'Editor')]]" \
        "[following-sibling::p[contains(@class, 'Title')]]",
      ).map { |p| create_contribution_info(p, "editor") }
    end

    def create_contribution_info(person, type, description = [])
      name = person.text.match(/^[^(]+/).to_s.strip
      email, org = person.xpath ".//a[@href]"
      entity = create_person name, email, org
      role = { type: type, description: description }
      RelatonBib::ContributionInfo.new(role: [role], entity: entity)
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

      cnt = RelatonBib::Contact.new(type: "uri", value: org[:href])
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
      case text
      when /OASIS Project Specification (\d+)/ then "#{num}-PS#{$1}"
      when /Committee Specification (\d+)/ then "#{num}-CS#{$1}"
      else num
      end
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
    # @return [RelatonOasis::DocumentType] document type
    #
    def parse_doctype
      type =  case text
              when /OASIS Project Specification/, /Committee Specification/
                "specification"
              when /Technical Memorandum/ then "memorandum"
              when /Technical Resolution/ then "resolution"
              else "standard"
              end
      DocumentType.new(type: type)
    end

    #
    # Parse technology area.
    #
    # @return [Array<String>] technology areas
    #
    def parse_technology_area(node)
      node.xpath("./summary/div/div/ul[@class='technology-areas__list']/li/a").map do |ta|
        ta.text.strip.gsub(/\s/, "-").sub("development", "Development")
      end
    end
  end
end
