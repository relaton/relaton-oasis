module RelatonOasis
  class OasisBibliographicItem < RelatonBib::BibliographicItem
    AREAS = %w[Cloud Content-Technologies Cybersecurity e-Business eGov/Legal
               Emergency-Management Energy Information-Modeling IoT
               Lifecycle-Integration Localization Messaging Privacy/Identity
               Security SOA Web-Services Software-Development Virtualization].freeze

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
        area = uta.size > 1 ? "areas" : "area"
        Util.warn "Unknown technology #{area}: `#{uta.join('`, `')}`\n" \
          "Valid values are: `#{AREAS.join('`, `')}`"
      end
      super
    end

    #
    # Fetsh flavor schema version.
    #
    # @return [String] flavor schema version
    #
    def ext_schema
      @ext_schema ||= schema_versions["relaton-model-oasis"]
    end

    # def ext_schema
    #   @ext_schema ||= schema_versions["relaton-model-oasis"]
    # end

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
    def to_xml(**opts) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
      super(**opts) do |b|
        if opts[:bibdata] && technology_area.any?
          ext = b.ext do
            doctype&.to_xml b
            editorialgroup&.to_xml b
            technology_area.each { |ta| b.send :"technology-area", ta }
          end
          ext["schema-version"] = ext_schema unless opts[:embedded]
        end
      end
    end

    #
    # Render bibliographic item as Hash.
    #
    # @param embedded [Boolean] true if embedded in another document
    # @return [Hash] bibliographic item as Hash
    #
    def to_hash(embedded: false)
      hash = super
      hash["ext"]["technology_area"] = technology_area if technology_area.any?
      hash
    end

    def has_ext?
      super || technology_area.any?
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
