FROM ruby:2.3
MAINTAINER Tom Duffield <tom@chef.io>

# We need `git` because oftentimes .gemspec depends on it for listing files
RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN gem install bundler && mkdir /app
COPY start /start
WORKDIR /app
CMD ["/start"]
