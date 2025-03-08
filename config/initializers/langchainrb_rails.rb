# frozen_string_literal: true

LangchainrbRails.configure do |config|
  # switch based on the configuration for llm in the rails.configuration
  llm = case Rails.configuration.ai_provider
        when "google"
          Langchain::LLM::GoogleGemini.new(api_key: ENV["GEMINI_API_KEY"])
        when "openai"
          Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"], llm_options: {base_url: ENV["OPENAI_API_BASE_URL"]})
        else
          Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"], llm_options: {base_url: ENV["OPENAI_API_BASE_URL"]})
        end

  config.vectorsearch = Langchain::Vectorsearch::Pgvector.new(
    llm: llm
  )
end
