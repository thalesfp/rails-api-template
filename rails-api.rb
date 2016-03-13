Paperclip = yes?("Add Paperclip for file upload?")
AWS = yes?("Add AWS SDK?")
Knock = yes?("Add Knock for authentication?")
Figaro = yes?("Use figaro for configuration?")
Heroku = yes?("Will you deploy to Heroku?")

# Remove comments
gsub_file 'Gemfile', /^#.*$\n/, ''
gsub_file 'Gemfile', "gem 'spring', :group => :development\n\n", '' 

insert_into_file 'Gemfile', after: "source 'https://rubygems.org'\n" do <<-EOF

ruby '2.3.0'
EOF
end

# Gems

gem 'versionist'
gem 'rack-cors', :require => 'rack/cors'

gem 'active_model_serializers', '0.10.0.rc4'

gem 'simple_enum'

gem 'paperclip', '~> 4.3' if Paperclip
gem 'aws-sdk-v1' if AWS

gem 'knock', github: 'nsarno/knock', branch: 'v2' if Knock

gem 'figaro' if Figaro

# Gem groups

gem_group :development do
  gem 'spring'
end

gem_group :test do
  gem 'shoulda-matchers', '~> 2.8.0'
  gem 'database_cleaner'
end

gem_group :production do
  gem 'puma'
  gem 'rails_12factor' if Heroku
end

gem_group :development, :test do
  gem 'rspec-rails'
  gem 'faker'
  gem 'factory_girl_rails', '~> 4.0'
end

after_bundle do
  remove_dir "app/views"
  remove_dir "app/assets"
  remove_dir "test"

  create_file 'config/initializers/inflections.rb' do <<-EOF
ActiveSupport::Inflector.inflections do |inflect|
  inflect.clear

  inflect.plural(/$/,  's')
  inflect.plural(/(s)$/i,  '\1')
  inflect.plural(/^(paí)s$/i, '\1ses')
  inflect.plural(/(z|r)$/i, '\1es')
  inflect.plural(/al$/i,  'ais')
  inflect.plural(/el$/i,  'eis')
  inflect.plural(/ol$/i,  'ois')
  inflect.plural(/ul$/i,  'uis')
  inflect.plural(/([^aeou])il$/i,  '\1is')
  inflect.plural(/m$/i,   'ns')
  inflect.plural(/^(japon|escoc|ingl|dinamarqu|fregu|portugu)ês$/i,  '\1eses')
  inflect.plural(/^(|g)ás$/i,  '\1ases')
  inflect.plural(/ão$/i,  'ões')
  inflect.plural(/^(irm|m)ão$/i,  '\1ãos')
  inflect.plural(/^(alem|c|p)ão$/i,  '\1ães')

  # Sem acentos...
  inflect.plural(/ao$/i,  'oes')
  inflect.plural(/^(irm|m)ao$/i,  '\1aos')
  inflect.plural(/^(alem|c|p)ao$/i,  '\1aes')

  inflect.singular(/([^ê])s$/i, '\1')
  inflect.singular(/^(á|gá|paí)s$/i, '\1s')
  inflect.singular(/(r|z)es$/i, '\1')
  inflect.singular(/([^p])ais$/i, '\1al')
  inflect.singular(/eis$/i, 'el')
  inflect.singular(/ois$/i, 'ol')
  inflect.singular(/uis$/i, 'ul')
  inflect.singular(/(r|t|f|v)is$/i, '\1il')
  inflect.singular(/ns$/i, 'm')
  inflect.singular(/sses$/i, 'sse')
  inflect.singular(/^(.*[^s]s)es$/i, '\1')
  inflect.singular(/ães$/i, 'ão')
  inflect.singular(/aes$/i, 'ao')
  inflect.singular(/ãos$/i, 'ão')    
  inflect.singular(/aos$/i, 'ao')
  inflect.singular(/ões$/i, 'ão')
  inflect.singular(/oes$/i, 'ao')
  inflect.singular(/(japon|escoc|ingl|dinamarqu|fregu|portugu)eses$/i, '\1ês')
  inflect.singular(/^(g|)ases$/i,  '\1ás')

  # Incontáveis
  inflect.uncountable %w( tórax tênis ônibus lápis fênix )

  # Irregulares
  inflect.irregular "país", "países"
end
EOF
end

  insert_into_file 'app/controllers/application_controller.rb', after: "class ApplicationController < ActionController::API\n" do <<-EOF
    include ActionController::Serialization
  EOF
  end

  insert_into_file 'app/controllers/application_controller.rb', after: "class ApplicationController < ActionController::API\n" do <<-EOF
    include Knock::Authenticatable
  EOF
  end if Knock

  insert_into_file '.gitignore', after: "/tmp\n" do <<-EOF

# MacOS X
.DS_Store

# Figaro
config/application.yml
  EOF
  end

  inside 'config' do

    BR = yes?("Configure i18n default locale to pt-BR?")

    insert_into_file 'application.rb', after: "# config.i18n.default_locale = :de\n" do <<-EOF
    config.i18n.default_locale = 'pt-BR'
    config.i18n.fallbacks = [:en]
    EOF
    end if BR
    
    create_file 'locales/pt-BR.yml' do <<-EOF
---
pt-BR:
  activerecord:
    attributes:
      usuario:
        password: "Senha"
      oferta:
        validade_inicial: "Validade Inicial"
        validade_final: "Validade Final"
    errors:
      models:
        oferta:
          attributes:
            validade_inicio:
              invalid_datetime: "data inválida"
              on_or_after: "precisa ser maior ou igual a hoje"
            validade_final:
              invalid_datetime: "data inválida"
              after: "precisa ser maior que a validade inicial"
  date:
    abbr_day_names:
    - Dom
    - Seg
    - Ter
    - Qua
    - Qui
    - Sex
    - Sáb
    abbr_month_names:
    - 
    - Jan
    - Fev
    - Mar
    - Abr
    - Mai
    - Jun
    - Jul
    - Ago
    - Set
    - Out
    - Nov
    - Dez
    day_names:
    - Domingo
    - Segunda-feira
    - Terça-feira
    - Quarta-feira
    - Quinta-feira
    - Sexta-feira
    - Sábado
    formats:
      default: "%d/%m/%Y"
      long: "%d de %B de %Y"
      short: "%d de %B"
    month_names:
    - 
    - Janeiro
    - Fevereiro
    - Março
    - Abril
    - Maio
    - Junho
    - Julho
    - Agosto
    - Setembro
    - Outubro
    - Novembro
    - Dezembro
    order:
    - :day
    - :month
    - :year
  datetime:
    distance_in_words:
      about_x_hours:
        one: aproximadamente 1 hora
        other: aproximadamente %{count} horas
      about_x_months:
        one: aproximadamente 1 mês
        other: aproximadamente %{count} meses
      about_x_years:
        one: aproximadamente 1 ano
        other: aproximadamente %{count} anos
      almost_x_years:
        one: quase 1 ano
        other: quase %{count} anos
      half_a_minute: meio minuto
      less_than_x_minutes:
        one: menos de um minuto
        other: menos de %{count} minutos
      less_than_x_seconds:
        one: menos de 1 segundo
        other: menos de %{count} segundos
      over_x_years:
        one: mais de 1 ano
        other: mais de %{count} anos
      x_days:
        one: 1 dia
        other: "%{count} dias"
      x_minutes:
        one: 1 minuto
        other: "%{count} minutos"
      x_months:
        one: 1 mês
        other: "%{count} meses"
      x_seconds:
        one: 1 segundo
        other: "%{count} segundos"
    prompts:
      day: Dia
      hour: Hora
      minute: Minuto
      month: Mês
      second: Segundo
      year: Ano
  errors:
    format: "%{attribute} %{message}"
    messages:
      accepted: deve ser aceito
      blank: não pode ficar em branco
      present: deve ficar em branco
      confirmation: não é igual a %{attribute}
      empty: não pode ficar vazio
      equal_to: deve ser igual a %{count}
      even: deve ser par
      exclusion: não está disponível
      greater_than: deve ser maior que %{count}
      greater_than_or_equal_to: deve ser maior ou igual a %{count}
      inclusion: não está incluído na lista
      invalid: não é válido
      less_than: deve ser menor que %{count}
      less_than_or_equal_to: deve ser menor ou igual a %{count}
      not_a_number: não é um número
      not_an_integer: não é um número inteiro
      odd: deve ser ímpar
      record_invalid: 'A validação falhou: %{errors}'
      restrict_dependent_destroy:
        one: Não é possível excluir o registro pois existe um %{record} dependente
        many: Não é possível excluir o registro pois existem %{record} dependentes
      taken: já está em uso
      too_long: 'é muito longo (máximo: %{count} caracteres)'
      too_short: 'é muito curto (mínimo: %{count} caracteres)'
      wrong_length: não possui o tamanho esperado (%{count} caracteres)
      other_than: deve ser diferente de %{count}
    template:
      body: 'Por favor, verifique o(s) seguinte(s) campo(s):'
      header:
        one: 'Não foi possível gravar %{model}: 1 erro'
        other: 'Não foi possível gravar %{model}: %{count} erros.'
  helpers:
    select:
      prompt: Por favor selecione
    submit:
      create: Criar %{model}
      submit: Salvar %{model}
      update: Atualizar %{model}
  number:
    currency:
      format:
        delimiter: "."
        format: "%u %n"
        precision: 2
        separator: ","
        significant: false
        strip_insignificant_zeros: false
        unit: R$
    format:
      delimiter: "."
      precision: 3
      separator: ","
      significant: false
      strip_insignificant_zeros: false
    human:
      decimal_units:
        format: "%n %u"
        units:
          billion:
            one: bilhão
            other: bilhões
          million:
            one: milhão
            other: milhões
          quadrillion:
            one: quatrilhão
            other: quatrilhões
          thousand: mil
          trillion:
            one: trilhão
            other: trilhões
          unit: ''
      format:
        delimiter: "."
        precision: 2
        significant: true
        strip_insignificant_zeros: true
      storage_units:
        format: "%n %u"
        units:
          byte:
            one: Byte
            other: Bytes
          gb: GB
          kb: KB
          mb: MB
          tb: TB
    percentage:
      format:
        delimiter: "."
        format: "%n%"
    precision:
      format:
        delimiter: "."
  support:
    array:
      last_word_connector: " e "
      two_words_connector: " e "
      words_connector: ", "
  time:
    am: ''
    formats:
      default: "%a, %d de %B de %Y, %H:%M:%S %z"
      long: "%d de %B de %Y, %H:%M"
      short: "%d de %B, %H:%M"
    pm: ''
    EOF
    end if BR

    insert_into_file 'application.rb', after: "config.active_record.raise_in_transactional_callbacks = true\n" do <<-EOF

    # Rack::Cors provides support for Cross-Origin Resource Sharing (CORS) for Rack compatible web applications.
    config.middleware.insert_before 0, "Rack::Cors" do
      allow do
        origins '*'
        resource '*', :headers => :any, :methods => [:get, :post, :options, :put, :delete]
      end
    end
    EOF
    end

    create_file 'aws.yml' do <<-EOF
development:
  access_key_id: <%= ENV['aws_access_key_id'] %>
  secret_access_key: <%= ENV['aws_secret_access_key'] %>

production:
  access_key_id: <%= ENV['aws_access_key_id'] %>
  secret_access_key: <%= ENV['aws_secret_access_key'] %>

test:
  access_key_id: <%= ENV['aws_access_key_id'] %>
  secret_access_key: <%= ENV['aws_secret_access_key'] %>
  EOF
    end if AWS

    create_file 'application.yml' do <<-EOF
# Database
database_host: localhost
database_name: #{@app_name}_development
database_username: 
database_password: 

# AWS
aws_access_key_id: 
aws_secret_access_key: 
aws_region: sa-east-1
aws_bucket:

test:
  # Database
  database_host: localhost
  database_name: #{@app_name}_test
  database_username: 
  database_password: 

  # AWS
  aws_access_key_id: 
  aws_secret_access_key: 
  aws_region: sa-east-1
  aws_bucket:
  EOF
    end

    insert_into_file 'application.rb', after: "config.active_record.raise_in_transactional_callbacks = true\n" do <<-EOF

    # Paperclip
    config.paperclip_defaults = {
      storage: :s3,
      s3_protocol: :https,
      region: ENV['aws_region'],
      bucket: ENV['aws_bucket'],
      url: ':s3_domain_url',
      path: '/:class/:attachment/:id_partition/:style/:filename'
    }
  EOF
    end if yes?("Configure Paperclip with AWS S3?")

    gsub_file 'routes.rb', /^\s{0,}#.*\n{0,1}$/, ''
    gsub_file 'routes.rb', /^\n$/, ""

    gsub_file 'database.yml', /^\s{0,}#.*\n{0,1}$/, ''
    gsub_file 'database.yml', /\n{1,}$/, "\n"

    gsub_file 'database.yml', /database: #{@app_name}_(development|test|production)/, "database: <%= ENV['database_name'] %>"
    gsub_file 'database.yml', /username: #{@app_name}/, "username: <%= ENV['database_username'] %>"
    gsub_file 'database.yml', /password: <%= ENV[\'#{@app_name}_DATABASE_PASSWORD\'] %>/, "password: <%= ENV['database_password'] %>"
  end

  run "spring stop"

  generate "rspec:install"
  generate "knock:install" if Knock
end