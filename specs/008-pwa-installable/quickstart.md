# Quickstart: testar o app instalável

O service worker só funciona em HTTPS ou em `localhost`. Em desenvolvimento (`npm run dev`) ele **não** é registrado;
teste com o build.

## Local (computador)
```bash
cd web && npm run build
docker build -t acervo . && docker run --rm -p 8080:8080 ...   # ou publique no Cloud Run
```
Abra `http://localhost:8080`, DevTools → Application: manifesto sem erros, service worker ativo,
Cache Storage `acervo-ui-*` sem nenhuma URL `/api`. Rode o Lighthouse (PWA instalável; acessibilidade não pode piorar).

## Celular real (Cloud Run, HTTPS)
1. **Android (Chrome)**: abra o endereço, entre, menu ⋮ → "Instalar app". Confira ícone e nome "Acervo" e a abertura em tela cheia.
2. **iPhone (Safari)**: a dica aparece; Compartilhar → "Adicionar à Tela de Início". Dispense a dica e confira que não volta.
3. **Atalhos** (Android): segure o ícone → "Nova nota" abre `/codigos/novo`; "Nova tarefa" abre Iniciativas pedindo a iniciativa.
4. **Offline**: com o app aberto uma vez, ative o modo avião e abra o app: aparece a interface e o aviso "Você está offline"; sem tela em branco.
   Edite uma nota offline: mostra "Não salvo. Tentando de novo…"; ao voltar a rede, salva.
5. **Atualização**: publique uma versão nova (merge na `main`), abra o app instalado: aparece "Nova versão disponível — Atualizar".
   Não recarrega sozinho; ao tocar em Atualizar, carrega a nova versão.
6. **Login**: entre no app instalado; "Sair" encerra a sessão e leva ao login.

## Regenerar os ícones
```bash
cd web
for s in 192 512; do convert -background none icon-src/icon.svg -resize ${s}x${s} public/icons/icon-$s.png; done
convert -background none icon-src/icon-maskable.svg -resize 512x512 public/icons/icon-maskable-512.png
convert -background none icon-src/icon.svg -resize 180x180 public/icons/apple-touch-icon.png
```
