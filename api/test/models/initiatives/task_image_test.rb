require "test_helper"

class Initiatives::TaskImageTest < ActiveSupport::TestCase
  PNG = "\x89PNG\r\n\x1A\n".b + "x".b * 20

  setup do
    @task = Initiatives::Initiative.create!(name: "I").tasks.create!(title: "T")
  end

  def attach(data, filename: "tela.png") = Initiatives::TaskImage.attach(@task, filename:, data:)

  test "o tipo vem dos bytes, não do nome" do
    {
      "image/png" => PNG,
      "image/jpeg" => "\xFF\xD8\xFF\xE0".b,
      "image/gif" => "GIF89a".b,
      "image/webp" => "RIFF\x00\x00\x00\x00WEBP".b
    }.each do |type, bytes|
      assert_equal type, attach(bytes, filename: "qualquer.txt").content_type
    end
  end

  test "recusa SVG e outros tipos" do
    assert_not attach("<svg xmlns='http://www.w3.org/2000/svg'/>", filename: "a.png").persisted?
    assert_not attach("texto").persisted?
  end

  test "recusa acima de 10 MB" do
    assert_not attach(PNG + "x".b * 10.megabytes).persisted?
  end

  test "limita a 10 por tarefa" do
    10.times { assert attach(PNG).persisted? }
    image = attach(PNG)
    assert_not image.persisted?
    assert_includes image.errors.full_messages.join, "limite de 10"
  end

  test "guarda só o nome do arquivo, sem caminho" do
    assert_equal "tela.png", attach(PNG, filename: "../../etc\\tela.png").filename
    assert_equal "imagem", attach(PNG, filename: nil).filename
  end

  test "without_data não carrega os bytes" do
    attach(PNG)
    assert_not Initiatives::TaskImage.without_data.first.has_attribute?(:data)
  end

  test "apagar a tarefa apaga as imagens" do
    attach(PNG)
    assert_difference("Initiatives::TaskImage.count", -1) { @task.destroy }
  end
end
