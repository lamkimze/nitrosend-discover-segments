module Segmentation
  module Providers
    # Optional LLM provider. Uses the same interface as Demo.
    # Set SEGMENTATION_PROVIDER=openai and OPENAI_API_KEY to enable.
    class OpenAi < Segmentation::Provider
      def analyse(profiles)
        raise "OPENAI_API_KEY is not configured" if ENV["OPENAI_API_KEY"].blank?

        # Intentionally thin: production would call the Responses/Chat API with
        # a structured JSON schema. For the challenge, fall back to Demo so
        # staging never depends on network credentials.
        Demo.new.analyse(profiles)
      end
    end
  end
end
