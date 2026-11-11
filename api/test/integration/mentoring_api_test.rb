require "test_helper"

class MentoringApiTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:owner) }

  def create_mentorship(use_suggested_questions: true, **attrs)
    post api_v1_mentoring_mentorships_path, as: :json,
         params: { mentorship: { mentor_name: "Ana", **attrs }, use_suggested_questions: }
    assert_response :created
    json
  end

  test "cria a mentoria com as perguntas sugeridas, ou sem elas" do
    mentorship = create_mentorship(topic: "Liderança")
    assert_equal "active", mentorship["status"]
    assert_equal Date.current.to_s, mentorship["started_on"]
    assert_equal({ "goals_open" => 0, "goals_achieved" => 0, "action_items_open" => 0, "last_meeting_on" => nil },
                 mentorship["summary"])

    get api_v1_mentoring_mentorship_questions_path(mentorship["id"])
    assert_equal Mentoring::SuggestedQuestions::ALL.size, json["data"].size
    assert_equal [ false ], json["data"].map { |q| q["answered"] }.uniq

    empty = create_mentorship(use_suggested_questions: false)
    get api_v1_mentoring_mentorship_questions_path(empty["id"])
    assert_equal [], json["data"]
  end

  test "nome do mentor é obrigatório" do
    post api_v1_mentoring_mentorships_path, as: :json, params: { mentorship: { mentor_name: " " } }
    assert_response :unprocessable_entity
    assert json["fields"].key?("mentor_name")
    assert_equal 0, Mentoring::Question.count
  end

  test "lista, mostra, altera e apaga mentorias" do
    id = create_mentorship(use_suggested_questions: false)["id"]
    get api_v1_mentoring_mentorships_path
    assert_equal [ id ], json["data"].map { |m| m["id"] }

    patch api_v1_mentoring_mentorship_path(id), as: :json, params: { mentorship: { status: "paused", cadence: "quinzenal" } }
    assert_response :ok
    assert_equal %w[paused quinzenal], json.values_at("status", "cadence")

    get api_v1_mentoring_mentorship_path(id)
    assert_equal "Ana", json["mentor_name"]

    delete api_v1_mentoring_mentorship_path(id), as: :json
    assert_response :no_content
    get api_v1_mentoring_mentorship_path(id)
    assert_response :not_found
  end

  test "responde, cria, move e apaga perguntas" do
    id = create_mentorship(use_suggested_questions: false)["id"]
    post api_v1_mentoring_mentorship_questions_path(id), as: :json, params: { question: { prompt: "Primeira?" } }
    first = json
    post api_v1_mentoring_mentorship_questions_path(id), as: :json, params: { question: { prompt: "Segunda?" } }
    second = json
    assert_equal [ 1, 2 ], [ first["position"], second["position"] ]

    patch api_v1_mentoring_question_path(first["id"]), as: :json, params: { question: { answer: "**Sim**" } }
    assert_response :ok
    assert json["answered"]

    post move_api_v1_mentoring_question_path(second["id"]), as: :json, params: { direction: "up" }
    assert_response :ok
    assert_equal %w[Segunda? Primeira?], json["data"].map { |q| q["prompt"] }

    post move_api_v1_mentoring_question_path(second["id"]), as: :json, params: { direction: "left" }
    assert_response :bad_request

    delete api_v1_mentoring_question_path(first["id"]), as: :json
    assert_response :no_content
  end

  test "objetivos com progresso das ações ligadas" do
    id = create_mentorship(use_suggested_questions: false)["id"]
    post api_v1_mentoring_mentorship_goals_path(id), as: :json,
         params: { goal: { title: "Delegar", success_criteria: "Time decide sozinho", target_on: "2027-03-01" } }
    assert_response :created
    goal = json
    assert_equal [ "not_started", 0 ], goal.values_at("status", "progress")

    post api_v1_mentoring_mentorship_action_items_path(id), as: :json, params: { action_item: { title: "x", goal_id: goal["id"], done: true } }
    patch api_v1_mentoring_goal_path(goal["id"]), as: :json, params: { goal: { progress: 40 } }
    assert_equal [ "in_progress", 40 ], json.values_at("status", "progress")
    assert_equal({ "total" => 1, "done" => 1 }, json["action_items"])

    get api_v1_mentoring_mentorship_goals_path(id)
    assert_equal [ goal["id"] ], json["data"].map { |g| g["id"] }

    patch api_v1_mentoring_goal_path(goal["id"]), as: :json, params: { goal: { progress: 140 } }
    assert_response :unprocessable_entity
  end

  test "encontros: novo vazio é de hoje, busca paginada e ações ligadas" do
    id = create_mentorship(use_suggested_questions: false)["id"]
    post api_v1_mentoring_mentorship_meetings_path(id), as: :json, params: {}
    assert_response :created
    today = json
    assert_equal Date.current.to_s, today["held_on"]
    assert_equal "Ana", today["mentor_name"]

    post api_v1_mentoring_mentorship_meetings_path(id), as: :json,
         params: { meeting: { held_on: "2026-01-10", agenda: "Plano de carreira", rating: 5, tags: "carreira, metas" } }
    old = json
    assert_equal %w[carreira metas], old["tags"]

    post api_v1_mentoring_mentorship_action_items_path(id), as: :json,
         params: { action_item: { title: "Ler livro", meeting_id: old["id"], due_on: "2026-01-20" } }
    assert_response :created
    assert_equal "2026-01-10", json["meeting_held_on"]
    assert json["overdue"]

    get api_v1_mentoring_mentorship_meetings_path(id)
    assert_equal [ today["id"], old["id"] ], json["data"].map { |m| m["id"] }
    assert_equal({ "total" => 1, "done" => 0 }, json["data"].last["action_items"])

    get api_v1_mentoring_mentorship_meetings_path(id), params: { q: "carreira" }
    assert_equal [ old["id"] ], json["data"].map { |m| m["id"] }
    assert_equal 1, json["meta"]["total"]

    get api_v1_mentoring_mentorship_action_items_path(id), params: { meeting_id: old["id"] }
    assert_equal [ "Ler livro" ], json["data"].map { |a| a["title"] }

    patch api_v1_mentoring_meeting_path(old["id"]), as: :json, params: { meeting: { rating: 9 } }
    assert_response :unprocessable_entity

    delete api_v1_mentoring_meeting_path(old["id"]), as: :json
    assert_response :no_content
    get api_v1_mentoring_mentorship_action_items_path(id)
    assert_equal [ nil ], json["data"].map { |a| a["meeting_id"] }
  end

  test "ações: concluir, filtrar e recusar vínculo de outra mentoria" do
    id = create_mentorship(use_suggested_questions: false)["id"]
    other = create_mentorship(use_suggested_questions: false)["id"]
    post api_v1_mentoring_mentorship_goals_path(other), as: :json, params: { goal: { title: "alheio" } }
    foreign_goal = json["id"]

    post api_v1_mentoring_mentorship_action_items_path(id), as: :json, params: { action_item: { title: "x", goal_id: foreign_goal } }
    assert_response :unprocessable_entity

    post api_v1_mentoring_mentorship_action_items_path(id), as: :json, params: { action_item: { title: "Ler" } }
    item = json
    patch api_v1_mentoring_action_item_path(item["id"]), as: :json, params: { action_item: { done: true } }
    assert json["done"]
    assert json["completed_at"].present?

    get api_v1_mentoring_mentorship_action_items_path(id), params: { status: "open" }
    assert_equal [], json["data"]
    get api_v1_mentoring_mentorship_action_items_path(id), params: { status: "done" }
    assert_equal [ item["id"] ], json["data"].map { |a| a["id"] }

    delete api_v1_mentoring_action_item_path(item["id"]), as: :json
    assert_response :no_content
  end

  test "competências e autoavaliações" do
    id = create_mentorship(use_suggested_questions: false)["id"]
    post api_v1_mentoring_mentorship_competencies_path(id), as: :json, params: { competency: { name: "Comunicação" } }
    assert_response :created
    competency = json
    post api_v1_mentoring_mentorship_competencies_path(id), as: :json, params: { competency: { name: "comunicação" } }
    assert_response :unprocessable_entity

    post api_v1_mentoring_mentorship_assessments_path(id), as: :json,
         params: { rated_on: "2026-09-01", ratings: [ { competency_id: competency["id"], score: 2 } ] }
    assert_response :ok
    post api_v1_mentoring_mentorship_assessments_path(id), as: :json,
         params: { rated_on: "2026-11-01", ratings: [ { competency_id: competency["id"], score: 4, comment: "melhorou" } ] }
    assert_equal %w[2026-09-01 2026-11-01], json["dates"]
    assert_equal [ 2, 4, 2 ], json["competencies"].first.values_at("first", "last", "delta")

    post api_v1_mentoring_mentorship_assessments_path(id), as: :json,
         params: { rated_on: "2026-11-01", ratings: [ { competency_id: competency["id"], score: 7 } ] }
    assert_response :unprocessable_entity

    delete api_v1_mentoring_mentorship_assessment_path(id, "2026-09-01"), as: :json
    assert_response :no_content
    get api_v1_mentoring_mentorship_assessments_path(id)
    assert_equal %w[2026-11-01], json["dates"]

    patch api_v1_mentoring_competency_path(competency["id"]), as: :json, params: { competency: { name: "Comunicação clara" } }
    assert_equal "Comunicação clara", json["name"]
    delete api_v1_mentoring_competency_path(competency["id"]), as: :json
    assert_response :no_content
    assert_equal 0, Mentoring::Rating.count
  end

  test "painel da mentoria" do
    id = create_mentorship(use_suggested_questions: false)["id"]
    post api_v1_mentoring_mentorship_questions_path(id), as: :json, params: { question: { prompt: "A?", answer: "sim" } }
    post api_v1_mentoring_mentorship_goals_path(id), as: :json, params: { goal: { title: "g", progress: 50 } }
    post api_v1_mentoring_mentorship_action_items_path(id), as: :json, params: { action_item: { title: "Ler", due_on: Date.current - 1 } }
    post api_v1_mentoring_mentorship_meetings_path(id), as: :json, params: { meeting: { held_on: Date.current - 2, rating: 4 } }

    get overview_api_v1_mentoring_mentorship_path(id)
    assert_response :ok
    assert_equal({ "total" => 1, "answered" => 1 }, json["questions"])
    assert_equal({ "total" => 1, "achieved" => 0, "average_progress" => 50 }, json["goals"])
    assert_equal [ 1, 0, 1 ], json["action_items"].values_at("total", "done", "overdue")
    assert_equal [ "Ler" ], json["action_items"]["next"].map { |a| a["title"] }
    assert_equal [ 1, 2, 4.0 ], json["meetings"].values_at("held", "days_since_last", "average_rating")
  end
end
