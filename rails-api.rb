# Add the current directory to the path Thor uses
# to look up files
def source_paths
  [File.expand_path(File.dirname(__FILE__))] + Array(super) 
end

Paperclip = yes?("Add Paperclip for file upload?")
AWS = yes?("Add AWS SDK?")
Knock = yes?("Add Knock for authentication?")
Figaro = yes?("Add Figaro for configuration?")
Heroku = yes?("Will you deploy to Heroku?")
UUID = yes?("Configure PostgreSQL UUID?")

# Remove comments
gsub_file 'Gemfile', /(^#.*\n*)|(^\n{2,})$/, ''
gsub_file 'Gemfile', "gem 'spring', :group => :development\n\n", '' 

insert_into_file 'Gemfile', after: "source 'https://rubygems.org'\n" do <<-EOF

ruby '2.3.0'
EOF
end

# Gems

gem 'ar-uuid'

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

    BR = yes?("Change i18n default locale to pt-BR?")

    inside 'initializers' do
      copy_file 'inflections.rb' if BR
    end

    inside 'locales' do
      copy_file 'pt-BR.yml' if BR
    end

    insert_into_file 'application.rb', after: "# config.i18n.default_locale = :de\n" do <<-EOF
    config.i18n.default_locale = 'pt-BR'
    config.i18n.fallbacks = [:en]
    EOF
    end if BR

    insert_into_file 'application.rb', after: "# config.time_zone = 'Central Time (US & Canada)'\n" do <<-EOF
    config.time_zone = 'Brasilia'
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

    insert_into_file 'routes.rb', after: "Rails.application.routes.draw do\n" do <<-EOF
  
  api_version(module: "V1", path: {value: "v1"}) do

  end
    EOF
    end

    gsub_file 'database.yml', /^\s{0,}#.*\n{0,1}$/, ''
    gsub_file 'database.yml', /\n{1,}$/, "\n"

    gsub_file 'database.yml', /database: #{@app_name}_(development|test|production)/, "database: <%= ENV['database_name'] %>"
    gsub_file 'database.yml', "username: #{@app_name}", "username: <%= ENV['database_username'] %>"
    gsub_file 'database.yml', "password: <%= ENV['#{@app_name.upcase}_DATABASE_PASSWORD'] %>", "password: <%= ENV['database_password'] %>"
  end

  run "spring stop"

  generate(:migration, "enable_uuid_extension") if UUID

  insert_into_file Dir['db/migrate/*_enable_uuid_extension.rb'].first, after: "def change\n" do <<-EOF
    enable_extension 'uuid-ossp'
  EOF
  end if UUID

  generate "rspec:install"
  generate "knock:install" if Knock
end