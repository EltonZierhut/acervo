module Initiatives
  # Descrição das tarefas: HTML guardado só com as tags e atributos que o editor produz.
  # O texto vem de colagens de páginas, e-mails e Word, e é exibido como HTML, então
  # tudo o que não está na lista é descartado (scripts, estilos, fontes, imagens, eventos).
  module RichText
    TAGS = %w[p br h1 h2 h3 strong b em i u s del code pre blockquote ul ol li a hr].freeze
    # data-type e data-checked marcam os itens de checklist.
    ATTRIBUTES = %w[href data-type data-checked].freeze
    BLOCKS = %w[p h1 h2 h3 blockquote pre ul ol li hr div].freeze
    HTML_TAG = %r{</?[a-z][^>]*>}i

    module_function

    # Texto puro (API, descrições antigas) vira parágrafos; HTML passa pelo sanitizador.
    # Devolve nil quando não sobra texto.
    def clean(value)
      return nil if value.blank?

      html = value.match?(HTML_TAG) ? sanitize(value) : from_plain_text(value)
      to_plain_text(html).blank? && !html.include?("<hr") ? nil : html
    end

    # Conteúdo que nunca é texto (CSS do Word, scripts) sai inteiro, não só a tag.
    DISCARDED = "script,style,template,iframe,object,embed,noscript,head,title,meta,link,svg,math".freeze

    def sanitize(html)
      fragment = Nokogiri::HTML5.fragment(html)
      fragment.css(DISCARDED).each(&:remove)
      Rails::HTML5::SafeListSanitizer.new.sanitize(fragment.to_html, tags: TAGS, attributes: ATTRIBUTES).to_s.strip
    end

    def from_plain_text(text)
      text.to_s.strip.split(/(?:\r?\n){2,}/).map { |block|
        "<p>#{ERB::Util.html_escape(block.strip).gsub(/\r?\n/, '<br>')}</p>"
      }.join
    end

    # Texto sem marcações, com quebra de linha entre os blocos (busca e prompt do executor).
    def to_plain_text(html)
      return "" if html.blank?

      fragment = Nokogiri::HTML5.fragment(html)
      fragment.css("br").each { |node| node.replace("\n") }
      fragment.css(BLOCKS.join(",")).each { |node| node.add_next_sibling("\n") }
      fragment.text.gsub(/[ \t]+/, " ").gsub(/ ?\n ?/, "\n").gsub(/\n{3,}/, "\n\n").strip
    end
  end
end
