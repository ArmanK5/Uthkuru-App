class GameController < ApplicationController
  protect_from_forgery with: :null_session

  COMMON_WORDS = %w[
    الله قال الذين من في على إلى ما لا إن أن هو هي هم هذا هذه ذلك تلك
  ].freeze

  def show
  end

  def round
    verse = fetch_random_verse
    word  = pick_target_word(verse)

    session[:target_word] = word
    session[:used_verse_keys] ||= []

    render json: { target_word: word }
  end

  def answer
    audio = params[:audio]
    return render json: { error: "No audio uploaded" }, status: :bad_request unless audio.present?

    transcript = transcribe(audio)
    return render json: { correct: false, transcript: nil, reason: "Transcription failed" } if transcript.blank?

    result = validate_answer(transcript, session[:target_word], session[:used_verse_keys] || [])

    if result[:correct]
      session[:used_verse_keys] << result[:verse_key]
    end

    render json: result.merge(transcript: transcript)
  end

  private

  def fetch_random_verse
    # Use Quran Foundation Random Verse endpoint here
    # Response should include verse text / verse_key / words
    # Replace this stub with the real HTTP call
    {
      "verse_key" => "93:1",
      "text_uthmani" => "وَالضُّحَىٰ",
      "words" => [
        { "text_uthmani" => "وَالضُّحَىٰ" }
      ]
    }
  end

  def pick_target_word(verse)
    words = Array(verse["words"]).map { |w| w["text_uthmani"].to_s.strip }
    cleaned = words.reject { |w| w.length < 3 || COMMON_WORDS.include?(normalize_arabic(w)) }
    chosen = cleaned.sample || words.sample
    chosen
  end

  def transcribe(audio_file)
    # Keep your speech-to-text provider here
    # Return plain Arabic transcript string
    "والضحى"
  end

  def validate_answer(transcript, target_word, used_verse_keys)
    return { correct: false, reason: "No active round" } if target_word.blank?

    # MVP logic:
    # 1. Search transcript in Quran Foundation Search API
    # 2. Take top 3-5 verse hits
    # 3. For each hit, fetch verse by key with words=true
    # 4. Check if target word exists in that verse
    # 5. Reject repeated verse_keys

    candidates = search_quran(transcript)

    match = candidates.find do |candidate|
      next if used_verse_keys.include?(candidate["verse_key"])

      verse = fetch_verse_by_key(candidate["verse_key"])
      verse_words = Array(verse["words"]).map { |w| normalize_arabic(w["text_uthmani"].to_s) }

      verse_words.include?(normalize_arabic(target_word))
    end

    if match
      {
        correct: true,
        verse_key: match["verse_key"],
        reason: nil
      }
    else
      {
        correct: false,
        verse_key: nil,
        reason: "No matching ayah containing the target word"
      }
    end
  end

  def search_quran(query)
    return [] if query.blank?

    # Replace with Quran Foundation Search API call
    # Should return verse hits with verse_key
    [
      { "verse_key" => "93:1" }
    ]
  end

  def fetch_verse_by_key(verse_key)
    # Replace with Quran Foundation Verse by Key call with words=true
    {
      "verse_key" => verse_key,
      "words" => [
        { "text_uthmani" => "وَالضُّحَىٰ" }
      ]
    }
  end

  def normalize_arabic(text)
    text.to_s
        .unicode_normalize(:nfkc)
        .gsub(/[\u064B-\u065F\u0670]/, "") # harakat
        .tr("أإآٱ", "ا")
        .tr("ى", "ي")
        .tr("ؤ", "و")
        .tr("ئ", "ي")
        .gsub(/[^\p{Arabic}\s]/, "")
        .squeeze(" ")
        .strip
  end
end
