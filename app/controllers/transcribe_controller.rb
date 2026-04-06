class TranscribeController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    audio = params[:audio]
    transcript = transcribe(audio)
    result = search_quran(transcript)

    render json: {
      transcript: transcript,
      verse_key:  result&.dig("verse_key"),
      text:       result&.dig("text_arabic")
    }
  end

  private

  def transcribe(audio_file)
  response = HTTParty.post(
    "https://router.huggingface.co/models/tarteel-ai/whisper-base-ar-quran",
    headers: {
      "Authorization" => "Bearer #{ENV['HUGGINGFACE_API_KEY']}",
      "Content-Type"  => "audio/webm"
    },
    body: audio_file.read
  )

  parsed = response.parsed_response
  Rails.logger.debug "HF Response: #{parsed.inspect}"

  if parsed.is_a?(Hash)
    parsed["text"]
  elsif parsed.is_a?(Array)
    parsed.first&.dig("text")
  else
    nil
  end
end

def search_quran(query)
  return nil if query.blank?

  response = HTTParty.get(
    "https://api.quran.com/api/v4/search",
    query: { q: query, language: "ar", size: 1 }
  )

  parsed = response.parsed_response
  Rails.logger.debug "Quran API Response: #{parsed.inspect}"

  parsed.dig("search", "results", 0) if parsed.is_a?(Hash)
end
end