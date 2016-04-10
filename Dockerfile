FROM rails:4.2


ENV RAILS_ENV production

RUN apt-get update && apt-get install -y redis-server
RUN service redis-server start

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

#COPY Gemfile /usr/src/app/
#COPY Gemfile.lock /usr/src/app/

RUN git clone https://github.com/contanko/contanko-app.git

RUN bundle install

#COPY . /usr/src/app

RUN bundle exec rake assets:precompile
RUN bundle exec sidekiq 

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
