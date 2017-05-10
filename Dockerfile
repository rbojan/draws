FROM ruby:2.3

RUN apt-get update -qq && apt-get install -y build-essential

ENV APP_HOME /app
ENV PORT 3000
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
RUN bundle install --without development:test --path vendor/bundle --binstubs vendor/bundle/bin -j4 --deployment

ADD . $APP_HOME

EXPOSE $PORT

CMD ["ruby", "app.rb", "-p", "$PORT"]
