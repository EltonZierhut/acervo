require "test_helper"

class FlashcardsApiTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:owner) }

  def create_deck(**attrs)
    post api_v1_flashcards_decks_path, as: :json, params: { deck: { name: "Inglês", **attrs } }
    assert_response :created
    json
  end

  def create_note(deck_id, **attrs)
    post api_v1_flashcards_deck_notes_path(deck_id), as: :json, params: { note: { front: "dog", back: "cachorro", **attrs } }
    assert_response :created
    json
  end

  test "cria baralho só com o nome, com limites padrão e contagens" do
    deck = create_deck
    assert_equal [ 20, 200, 0 ], deck.values_at("new_per_day", "reviews_per_day", "card_count")
    assert_equal({ "new" => 0, "learning" => 0, "review" => 0 }, deck["due"])
  end

  test "nome é obrigatório e único" do
    create_deck
    post api_v1_flashcards_decks_path, as: :json, params: { deck: { name: "inglês" } }
    assert_response :unprocessable_entity
    assert json["fields"].key?("name")
  end

  test "lista baralhos em ordem alfabética com as contagens do dia" do
    b = create_deck(name: "Biologia")
    a = create_deck(name: "alemão")
    create_note(b["id"], note_type: "basic_reversed")

    get api_v1_flashcards_decks_path
    assert_response :ok
    assert_equal [ a["id"], b["id"] ], json["data"].map { |d| d["id"] }
    assert_equal 2, json["data"].last["card_count"]
    assert_equal 2, json["data"].last["due"]["new"]
  end

  test "notas: cria, busca, edita, suspende, recomeça e apaga" do
    deck = create_deck
    note = create_note(deck["id"], tags: "Animais, básico", note_type: "basic_reversed")
    assert_equal %w[animais básico], note["tags"]
    assert_equal [ 0, 1 ], note["cards"].map { |c| c["ordinal"] }
    create_note(deck["id"], front: "table", back: "mesa")

    get api_v1_flashcards_deck_notes_path(deck["id"]), params: { q: "cachor" }
    assert_equal [ note["id"] ], json["data"].map { |n| n["id"] }

    patch api_v1_flashcards_note_path(note["id"]), as: :json, params: { note: { note_type: "basic", suspended: true } }
    assert_response :ok
    assert_equal 1, json["cards"].size
    assert json["suspended"]

    post reset_api_v1_flashcards_note_path(note["id"]), as: :json
    assert_response :ok
    assert_equal "new", json["cards"].first["state"]

    delete api_v1_flashcards_note_path(note["id"]), as: :json
    assert_response :no_content
    get api_v1_flashcards_note_path(note["id"])
    assert_response :not_found
  end

  test "nota sem verso é recusada" do
    deck = create_deck
    post api_v1_flashcards_deck_notes_path(deck["id"]), as: :json, params: { note: { front: "x", back: "" } }
    assert_response :unprocessable_entity
    assert json["fields"].key?("back")
  end

  test "estudo: mostra o cartão com os intervalos e a resposta traz o próximo" do
    deck = create_deck
    create_note(deck["id"], front: "**dog**", back: "cachorro", note_type: "basic_reversed")

    get api_v1_flashcards_deck_study_path(deck["id"])
    assert_response :ok
    card = json["card"]
    assert_equal [ "**dog**", "cachorro" ], card.values_at("question", "answer")
    assert_equal({ "1" => "1 min", "2" => "6 min", "3" => "10 min", "4" => "4 dias" }, card["intervals"])
    assert_equal({ "new" => 2, "learning" => 0, "review" => 0 }, json["counts"])

    post api_v1_flashcards_card_review_path(card["id"]), as: :json, params: { rating: 4, duration_ms: 3200 }
    assert_response :ok
    assert_equal "cachorro", json["card"]["question"]
    assert_equal 1, json["counts"]["new"]

    post api_v1_flashcards_card_review_path(json["card"]["id"]), as: :json, params: { rating: 4 }
    assert_nil json["card"]
    assert_nil json["next_due_at"]

    review = Flashcards::Review.order(:id).first
    assert_equal [ 4, "new", 3200 ], [ review.rating, review.state_before, review.duration_ms ]
  end

  test "estudo: cartão em aprendizado informa quando volta" do
    deck = create_deck
    create_note(deck["id"])
    get api_v1_flashcards_deck_study_path(deck["id"])

    post api_v1_flashcards_card_review_path(json["card"]["id"]), as: :json, params: { rating: 3 }
    assert_nil json["card"]
    assert_equal 1, json["counts"]["learning"]
    assert_not_nil json["next_due_at"]
  end

  test "resposta inválida ou de nota suspensa é recusada" do
    deck = create_deck
    note = create_note(deck["id"])
    card_id = note["cards"].first["id"]

    post api_v1_flashcards_card_review_path(card_id), as: :json, params: { rating: 7 }
    assert_response :unprocessable_entity

    patch api_v1_flashcards_note_path(note["id"]), as: :json, params: { note: { suspended: true } }
    post api_v1_flashcards_card_review_path(card_id), as: :json, params: { rating: 3 }
    assert_response :unprocessable_entity
    assert_equal 0, Flashcards::Review.count
  end

  test "apagar baralho apaga as notas" do
    deck = create_deck
    note = create_note(deck["id"])
    delete api_v1_flashcards_deck_path(deck["id"]), as: :json
    assert_response :no_content
    get api_v1_flashcards_note_path(note["id"])
    assert_response :not_found
  end
end
