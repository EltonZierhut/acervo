# Modelo de dados: Códigos como bloco de notas rápido

## Nota (`Codes::Snippet`, tabela `codes_snippets`)

| Campo | Tipo | Regras | Mudança |
|-------|------|--------|---------|
| `id` | bigint | | |
| `title` | string, **agora opcional** | até 200 caracteres; em branco vira `null` | remove `NOT NULL` |
| `content` | text, obrigatório | não vazio nem só com espaços; até 1 MB; sem byte nulo; guardado sem alteração | |
| `language` | string, opcional | minúsculas | |
| `description` | text, opcional | | |
| `tags` | string[] | minúsculas, sem repetição; aceita array ou texto separado por vírgulas | correção |
| `tags_text` | texto gerado | tags separadas por espaço; usado na busca por pedaços | nova |
| `searchable` | tsvector gerado | como hoje | |
| `project_id` | | | **removido** |
| `created_at`, `updated_at` | datetime | `updated_at` só muda quando há alteração real | |

**Valor derivado**: `display_title` é o título, ou a primeira linha não vazia do conteúdo, sem espaços
nas pontas e cortada em 200 caracteres.

**Ordenação**: `updated_at` decrescente; com busca, por relevância e depois `updated_at`.

## Removido

Tabela `codes_projects` e o model `Codes::Project`.

## Migration

- **`up`**: remove `project_id`, apaga `codes_projects`, retira o `NOT NULL` de `title` e adiciona `tags_text`.
- **`down`**: preenche os títulos vazios com a primeira linha do conteúdo, restaura o `NOT NULL`, recria
  `codes_projects` **vazia** e `project_id` sem valores, e remove `tags_text`.
- Os projetos e os vínculos não são recuperáveis, conforme FR-018. O restante das notas é preservado.
