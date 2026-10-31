# Impede que senhas, tokens e dados sensíveis apareçam nos logs.
Rails.application.config.filter_parameters += %i[
  passw email_address token secret _key crypt salt certificate otp ssn cvv cvc
]
