# Administração da conta pelo terminal (não há cadastro nem recuperação de senha pela interface).
# Contrato: specs/001-email-password-auth/contracts/cli.md
#
#   bin/rails acervo:user:create
#   bin/rails acervo:user:reset_password
#
# A senha é sempre digitada de forma interativa, sem eco, para não ficar no histórico do shell.
require "io/console"

module AcervoUserCli
  module_function

  def ask(label)
    print "#{label}: "
    $stdout.flush
    $stdin.gets.to_s.chomp
  end

  def ask_secret(label)
    print "#{label}: "
    $stdout.flush
    value =
      if $stdin.respond_to?(:noecho) && $stdin.tty?
        $stdin.noecho(&:gets).tap { puts }
      else
        $stdin.gets
      end
    value.to_s.chomp
  end

  def fail_with(*messages)
    messages.flatten.each { |message| warn message }
    exit 1
  end
end

namespace :acervo do
  namespace :user do
    desc "Cria a conta de acesso ao Acervo (nesta versão, apenas uma)"
    task create: :environment do
      cli = AcervoUserCli

      if (existing = User.first)
        cli.fail_with("Já existe um usuário (#{existing.email_address}). Nesta versão o Acervo tem um único usuário.")
      end

      email = cli.ask("E-mail")
      password = cli.ask_secret("Senha (mín. #{User::PASSWORD_MIN_LENGTH} caracteres)")
      confirmation = cli.ask_secret("Confirme a senha")

      user = User.new(email_address: email, password:, password_confirmation: confirmation)
      cli.fail_with(user.errors.full_messages) unless user.save

      puts "Usuário #{user.email_address} criado. Entre pela tela de login do Acervo."
    end

    desc "Redefine a senha de uma conta e encerra todas as sessões dela"
    task reset_password: :environment do
      cli = AcervoUserCli

      email = cli.ask("E-mail")
      user = User.find_by(email_address: email.strip.downcase)
      cli.fail_with("Nenhum usuário com o e-mail #{email.strip}.") unless user

      password = cli.ask_secret("Nova senha (mín. #{User::PASSWORD_MIN_LENGTH} caracteres)")
      confirmation = cli.ask_secret("Confirme a nova senha")

      begin
        closed = user.reset_password!(password, confirmation)
      rescue ActiveRecord::RecordInvalid
        cli.fail_with(user.errors.full_messages)
      end

      puts "Senha redefinida. #{closed} sessão(ões) encerrada(s)."
    end
  end
end
