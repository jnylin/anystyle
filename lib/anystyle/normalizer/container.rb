# coding: utf-8
module AnyStyle
  class Normalizer
    class Container < Normalizer
      @keys = [:'container-title']

      def normalize(item, **opts)
        map_values(item) do |_, value|
          value
            .sub(/^[Ii]n(?::|\s+the)?\s+(\p{^Ll})/, '\1')
            .sub(/^of\s+/, '')
            .sub(/^收入/, '')
            .sub(/^(\w+ )?presented at (the )?/i, '')
            .sub(/^[Ii](?:\s+|:)\s+(\p{^Ll})/, '\1')
        end
      end
    end
  end
end
