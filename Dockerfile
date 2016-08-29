FROM ruby:2.3.0

ENV APP_HOME=/myapp
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
    BUNDLE_JOBS=2 \
    BUNDLE_PATH=/bundle

COPY Gemfile* $APP_HOME/

RUN bundle install

RUN apt-get update -qq \
    && apt-get install -y \
      build-essential \
      libpq-dev \
      nodejs \
# Remove git so that messing with git repo is not possible in container
    && apt-get remove -y git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/

# Make it possible to run rspec, rake, bundle, etc. from a shell session
# in the container without prepending bundle exec
ENV PATH $PATH:$APP_HOME/bin

# Copy files last so that if files have changed, the other build steps
# will not be invalidated and can still use the cache.
COPY . $APP_HOME/
