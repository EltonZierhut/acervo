#!/bin/sh
# Liga o PostgreSQL da execução e depois roda o comando (o Claude Code). Tudo do banco vai para um arquivo
# de log: a saída padrão é o resultado JSON do agente e não pode ser misturada.
# Se o banco não subir, o agente roda mesmo assim e informa no PR que não conseguiu testar.

pg_root="$HOME/postgres"
log="$pg_root/server.log"

start_postgres() {
  mkdir -p "$pg_root/socket" || return 1
  # O usuário do --user não existe no /etc/passwd; o initdb e o postgres exigem um nome.
  echo "agent:x:$(id -u):$(id -g):agent:$HOME:/bin/sh" > "$pg_root/passwd"
  echo "agent:x:$(id -g):" > "$pg_root/group"
  export LD_PRELOAD=libnss_wrapper.so NSS_WRAPPER_PASSWD="$pg_root/passwd" NSS_WRAPPER_GROUP="$pg_root/group"

  initdb -D "$pg_root/data" -U postgres --auth=trust -E UTF8 --locale=C.UTF-8 >"$log" 2>&1 || return 1
  pg_ctl -D "$pg_root/data" -l "$log" -w \
    -o "-c listen_addresses=localhost -c unix_socket_directories=$pg_root/socket -c fsync=off" start >>"$log" 2>&1
}

if ! (start_postgres); then
  echo "Aviso: o PostgreSQL da imagem do agente não subiu. Log: $log" >&2
fi

exec "$@"
