# Entrega os arquivos do app instalável (PWA) que precisam ficar na raiz e fora de /assets:
# /sw.js, /manifest.webmanifest e /icons/*. Ficam em frontend/ (como o index.html), fora de
# public/, para não receberem o cache de um ano dos assets (ver specs/008-pwa-installable).
#
# Sem login, como o SpaController: são só arquivos da interface, sem dados.
class PwaController < ActionController::API
  DIR = Rails.root.join("frontend")

  # sw.js e manifesto sem cache: o navegador precisa ver a versão nova na hora.
  FILES = {
    "sw.js" => { type: "text/javascript", cache: "no-cache" },
    "manifest.webmanifest" => { type: "application/manifest+json", cache: "no-cache" }
  }.freeze

  def service_worker = send_ui_file(DIR.join("sw.js"), **FILES["sw.js"])

  def manifest = send_ui_file(DIR.join("manifest.webmanifest"), **FILES["manifest.webmanifest"])

  def icon
    send_ui_file(DIR.join("icons", params[:name]), type: "image/png", cache: "public, max-age=86400")
  end

  private

  def send_ui_file(path, type:, cache:)
    return head :not_found unless path.file?

    response.headers["Cache-Control"] = cache
    send_file path, type: type, disposition: "inline"
  end
end
