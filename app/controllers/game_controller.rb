class GameController < ApplicationController
  def show
  end

  def round
    session[:target_word] = "الصابرين"

    render json: {
      target_word: session[:target_word]
    }
  end

  def answer
    audio = params[:audio]

    unless audio.present?
      return render json: { correct: false, reason: "No audio uploaded" }, status: :bad_request
    end

    begin
      transcript = transcribe(audio)
    rescue => e
      return render json: {
        correct: false,
        transcript: nil,
        verse_key: nil,
        reason: e.message
      }, status: :unprocessable_entity
    end

    target_word = session[:target_word]

    if target_word.blank?
      return render json: {
        correct: false,
        transcript: transcript,
        verse_key: nil,
        reason: "No active round. Press Start Round first."
      }, status: :unprocessable_entity
    end

    if transcript.blank?
      return render json: {
        correct: false,
        transcript: nil,
        verse_key: nil,
        reason: "Transcription failed"
      }, status: :unprocessable_entity
    end

    correct = matches_target_word?(transcript, target_word)

    render json: {
      correct: correct,
      transcript: transcript,
      verse_key: correct ? "2:153" : nil,
      reason: correct ? nil : "Target word not found in transcript"
    }
  end

  private

  def transcribe(audio_file)
    response = HTTParty.post(
      "https://router.huggingface.co/hf-inference/models/openai/whisper-large-v3",
      headers: {
        "Authorization" => "Bearer #{ENV["HUGGINGFACE_API_KEY"]}",
        "Content-Type" => audio_file.content_type.presence || "audio/webm"
      },
      body: audio_file.read
    )

    Rails.logger.debug "HF status: #{response.code}"
    Rails.logger.debug "HF body: #{response.body}"

    parsed = response.parsed_response

    if response.code == 403
      raise "Hugging Face token is missing Inference Providers permission"
    end

    return parsed["text"] if response.success? && parsed.is_a?(Hash)

    nil
  end

  def normalize_arabic(text)
    text.to_s
        .unicode_normalize(:nfkc)
        .gsub(/[\u064B-\u065F\u0670]/, "")
        .tr("أإآٱ", "ا")
        .tr("ى", "ي")
        .tr("ؤ", "و")
        .tr("ئ", "ي")
        .gsub(/[^\p{Arabic}\s]/, "")
        .squeeze(" ")
        .strip
  end

  def matches_target_word?(transcript, target_word)
    arabic_transcript = normalize_arabic(transcript)
    latin_transcript = normalize_latin(transcript)

    aliases = target_aliases(target_word)

    aliases.any? do |alias_word|
      arabic_alias = normalize_arabic(alias_word)
      latin_alias = normalize_latin(alias_word)

      (arabic_alias.present? && arabic_transcript.include?(arabic_alias)) ||
        (latin_alias.present? && latin_transcript.include?(latin_alias))
    end
  end

  def target_aliases(target_word)
    case normalize_arabic(target_word)
    when "الصابرين"
      [
        "الصابرين",
        "sabireen",
        "sabirin",
        "sabrin",
        "saberin",
        "sabereen",
        "soberin",
        "sobereen",
        "assabirin",
        "assoberin",
        "as sabirin",
        "as soberin",
        "alsabirin",
        "alsoberin",
        "al sabirin",
        "al soberin"
      ]
    else
      [ target_word.to_s ]
    end
  end

  def normalize_latin(text)
    I18n.transliterate(text.to_s)
        .downcase
        .gsub(/[^a-z\s]/, "")
        .squeeze(" ")
        .strip
  end
end
