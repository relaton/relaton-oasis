module RelatonOasis
  module Util
    extend RelatonBib::Util

    def self.logger
      RelatonOasis.configuration.logger
    end
  end
end
