# Entrega a interface React (SPA) nas rotas de navegação.
#
# Não herda do ApplicationController de propósito: a página só contém a interface
# (sem dados), e é ela que mostra a tela de login. Os dados continuam protegidos na API.
#
# O index.html fica em frontend/, fora de public/, para não ser servido pelo servidor de
# arquivos estáticos com o cache longo dos assets (ver specs/002-deploy-gcp/research.md, R2).
class SpaController < ActionController::API
  INDEX_PATH = Rails.root.join("frontend", "index.html")

  def index
    unless INDEX_PATH.exist?
      return render plain: "Interface não compilada. Em desenvolvimento, use o Vite (http://localhost:5173).",
        status: :not_found
    end

    response.headers["Cache-Control"] = "no-cache"
    send_file INDEX_PATH, type: "text/html", disposition: "inline"
  end
end
