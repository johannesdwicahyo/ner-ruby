# frozen_string_literal: true

module NerRuby
  module Models
    class Base
      def predict(input_ids)
        raise NotImplementedError, "#{self.class}#predict not implemented"
      end
    end
  end
end
