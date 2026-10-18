namespace :users do
  desc "Crée un compte et affiche un mot de passe généré, une seule fois."
  task :invite, [ :email_address ] => :environment do |_t, args|
    email_address = args.email_address.presence || abort("Usage: bin/rails \"users:invite[someone@example.com]\"")

    password = SecureRandom.alphanumeric(16)
    user = User.create!(email_address: email_address, password: password)

    puts "Compte créé pour #{user.email_address}."
    puts "Mot de passe (à transmettre, non enregistré ailleurs) : #{password}"
  end

  desc "Régénère le mot de passe d'un compte existant et l'affiche, une seule fois."
  task :reset_password, [ :email_address ] => :environment do |_t, args|
    email_address = args.email_address.presence || abort("Usage: bin/rails \"users:reset_password[someone@example.com]\"")

    user = User.find_by(email_address: email_address) || abort("Aucun compte pour #{email_address}.")
    password = SecureRandom.alphanumeric(16)
    user.update!(password: password)

    puts "Nouveau mot de passe pour #{user.email_address} : #{password}"
  end
end
