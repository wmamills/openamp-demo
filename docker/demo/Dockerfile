FROM openamp/demo-lite

# Install build tools and "nice to haves"
RUN apt-get --quiet=2 update && apt-get install --quiet=2 --assume-yes mc ncdu

# most of this is already there but add the extras
ADD user-dev-extra.tar.gz /home/dev

# default command logs in as dev
CMD su -l dev
