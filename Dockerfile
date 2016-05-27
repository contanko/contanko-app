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

RUN git clone https://github.com/contanko/contanko-app.git /usr/src/app
#RUN SecureRandom.hex(64) > .secret

RUN bundle install

#COPY . /usr/src/app

RUN bundle exec rake assets:precompile
#RUN bundle exec sidekiq
#RUN rake secret > .secret

RUN rake db:migrate
RUN rake db:seed


#ENV SECRET_KEY_BASE cat .secret

EXPOSE 3000
# Add boot script
#ADD ./boot.sh /opt/boot.sh
#ADD ./config/secrets.yml /usr/src/app/config/secrets.yml


RUN chmod +x /usr/src/app/boot.sh

# Run the boot script
CMD /usr/src/app/boot.sh
#CMD ["rails", "server", "-b", "0.0.0.0"]
#CMD rails server -b 0.0.0.0; service redis-server start; bundle exec sidekiq
