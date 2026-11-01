# Token do programa executor. Em produção: bin/prod-rails acervo:executor:create
namespace :acervo do
  namespace :executor do
    desc "Cria o token do executor e invalida o anterior (o valor só aparece agora)"
    task create: :environment do
      token = Initiatives::Executor.rotate_token!
      puts "Token do executor (guarde em ~/.config/acervo-executor/config.yml; ele não será mostrado de novo):"
      puts token
    end
  end
end
