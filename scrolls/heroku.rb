heroku_name = app_name.gsub('_','')

inject_into_file 'Gemfile', "\nruby '1.9.3'\n", :after => "source 'https://rubygems.org'"

after_everything do
  if config['create']
    say_wizard "Creating Heroku app '#{heroku_name}.heroku.com'"
    while !system("heroku create #{heroku_name}")
      heroku_name = ask_wizard("What do you want to call your app? ")
    end
  else
    git :remote => "add heroku git@heroku.com:#{heroku_name}.git"
  end


  if config['staging']
    staging_name = "#{heroku_name}-staging"
    say_wizard "Creating staging Heroku app '#{staging_name}.heroku.com'"
    while !system("heroku create #{staging_name}")
      staging_name = ask_wizard("What do you want to call your staging app?")
    end
    git :remote => "rm heroku"
    git :remote => "add production git@heroku.com:#{heroku_name}.git"
    git :remote => "add staging git@heroku.com:#{staging_name}.git"
    say_wizard "Created branches 'production' and 'staging' for Heroku deploy."
  end

  unless config['domain'].blank?
    run "heroku addons:add custom_domains"
    run "heroku domains:add #{config['domain']}"
  end
end

if config['deploy']
  finally do
    git :push => "#{config['staging'] ? 'staging' : 'heroku'} master"
    run "heroku run rake db:migrate"
  end
end

__END__

name: Heroku
description: Create Heroku application and instantly deploy.
author: mbleigh
run_after: [git]
exclusive: deployment
category: deployment
tags: [provider]
requires: [git, postgresql]

config:
  - create:
      prompt: "Automatically create appname.heroku.com?"
      type: boolean
  - staging:
      prompt: "Create staging app? (appname-staging.heroku.com)"
      type: boolean
      if: create
  - domain:
      prompt: "Specify custom domain (or leave blank):"
      type: string
      if: create
  - deploy:
      prompt: "Deploy immediately?"
      type: boolean 
      if: create
