threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# O Cloud Run define PORT=8080. Um único processo (sem `workers`): o limite de
# tentativas de login usa cache em memória, que não é compartilhado entre processos.
port ENV.fetch("PORT", 3000)

plugin :tmp_restart
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
