# frozen_string_literal: true

module RelatonOasis
  # Class methods for search Cenelec standards.
  class OasisBibliography
    ENDPOINT = "https://raw.githubusercontent.com/relaton/relaton-data-oasis/main/"
    INDEX_FILE = "index-v1.yaml"

    class << self
      # @param text [String]
      # @return [RelatonOasis::HitCollection]
      def search(text, _year = nil) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        /^(?:OASIS\s)?(?<code>.+)/ =~ text
        index = Relaton::Index.find_or_create(
          :oasis, url: "#{ENDPOINT}index-v1.zip", file: INDEX_FILE
        )
        row = index.search(code).min_by { |i| i[:id] }
        return unless row

        agent = Mechanize.new
        resp = agent.get "#{ENDPOINT}#{row[:file]}"
        return unless resp.code == "200"

        hash = YAML.safe_load resp.body
        hash["fetched"] = Date.today.to_s
        OasisBibliographicItem.from_hash hash
      rescue Mechanize::ResponseCodeError, OpenURI::HTTPError => e
        return if e.response_code == "404"

        raise RelatonBib::RequestError, e.message
      end

      # @param code [String] the CEN standard Code to look up
      # @param year [String] the year the standard was published (optional)
      # @param opts [Hash] options; restricted to :all_parts if all-parts
      #   reference is required
      # @return [RelatonOasis::OasisBibliographicItem, nil]
      def get(code, year = nil, _opts = {}) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        Util.info "Fetching from Relaton repository ...", key: code
        bibitem = search code, year
        if bibitem
          docid = bibitem.docidentifier.detect(&:primary).id
          Util.info "Found: `#{docid}`", key: code
        else
          Util.info "Not found.", key: code
        end
        bibitem
      end
    end
  end
end
