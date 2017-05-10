FROM ruby:2.3

RUN apt-get update -qq && apt-get install -y build-essential

ENV APP_HOME /app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
# RUN bundle install --without development:test --path vendor/bundle --binstubs vendor/bundle/bin -j4 --deployment
RUN bundle install --without development:test

ADD . $APP_HOME

CMD ["ruby", "app.rb", "-p", "5000", "-o", "0.0.0.0"]
