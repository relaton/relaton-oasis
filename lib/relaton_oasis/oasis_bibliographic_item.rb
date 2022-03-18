module RelatonOasis
  class OasisBibliographicItem < RelatonBib::BibliographicItem
    AREAS = %w[Cloud Content-Technologies Cybersecurity e-Business eGov/Legal
               Emergency-Management Energy Information-Modeling IoT
               Lifecycle-Integration Localization Messaging Privacy/Identity
               Security SOA Web-Services].freeze

    attr_reader :technology_area

    #
    # Initialize OasisBibliographicItem.
    #
    # @param [Array<String>] technology_area technology areas
    #
    def initialize(**args)
      @technology_area = args.delete(:technology_area) || []
      uta = @technology_area.reject { |a| AREAS.include? a }
      if uta.any?
        warn "[relaton-oasis] WARNING Unknown technology area: #{uta.join(', ')}"
        warn "[relaton-oasis] (Valid values are: #{AREAS.join(', ')})"
      end
      super
    end

    # @param hash [Hash]
    # @return [RelatonBipm::BipmBibliographicItem]
    def self.from_hash(hash)
      item_hash = ::RelatonOasis::HashConverter.hash_to_bib(hash)
      new(**item_hash)
    end

    #
    # Render bibliographic item as XML.
    #
    # @param opts [Hash] options
    # @option opts [Nokogiri::XML::Builder] :builder XML builder
    # @option opts [Boolean] :bibdata true if bibdata is rendered
    # @option opts [String] :lang language code
    #
    # @return [String] XML representation of bibliographic item
    #
    def to_xml(**opts)
      super(**opts) do |b|
        if opts[:bibdata] && technology_area.any?
          b.ext do
            b.doctype doctype if doctype
            editorialgroup&.to_xml b
            technology_area.each { |ta| b.send :"technology-area", ta }
          end
        end
      end
    end

    #
    # Render bibliographic item as Hash.
    #
    # @return [Hash] bibliographic item as Hash
    #
    def to_hash
      hash = super
      hash["technology_area"] = technology_area if technology_area.any?
      hash
    end

    #
    # Render bibliographic item as AsciiBib.
    #
    # @param prefix [String] prefix
    #
    # @return [String] bibliographic item as AsciiBib
    #
    def to_asciibib(prefix = "")
      pref = prefix.empty? ? prefix : "#{prefix}."
      out = super
      technology_area.each do |ta|
        out += "#{pref}technology_area:: #{ta}\n"
      end
      out
    end
  end
end
