# run commands via docker compose, including custom commands defined in .env

# allow docker compose to be overridden, eg to use old docker-compose or podman-compose
DOCKER_COMPOSE := docker compose

# get variables from .env
-include .env
export

# use '>' to prefix the start of make target commands (default is tab)
.RECIPEPREFIX = >

# get the custom commands from .env COMMAND_* variables
ENV_COMMANDS := $(filter COMMAND_%, $(.VARIABLES))

# define the newline character - used to define the custom commands
# note: the two blank lines are necessary as make removes single blank lines
define \n


endef

# show help by default
.DEFAULT_GOAL := help
.PHONY: help # ensure make always runs the command
help: # list all make commands
# extract make targets and:
#   - get static target comments from Makefile
#   - get dynamic targets from the .env
# '@' at the start of the command stops make from echoing the command
# use tput to highlight the command
> @make --just-print --no-builtin-rules --print-data-base --question \
    | # remove targets prefixed by the 'Not a target' comment \
    sed --expression='/^# Not a target/,+1d' \
    | # get just the targets \
    grep '^[^#]*:$$' \
    | # remove trailing ':' \
    sed --expression='s/:$$//' \
    | sort \
    | while read COMMAND; do \
        echo -n "$(shell tput bold)$${COMMAND}$(shell tput sgr0): "; \
        # get the command's comment from Makefile \
        grep "^$${COMMAND}:" Makefile | sed --expression="s/.*# //"; \
        # get the command's comment from .env \
        grep "^COMMAND_$${COMMAND}=" .env 2>/dev/null | sed --expression='s/.*# //' --expression='s/} \\$$//'; \
      done \
    | # format the output nicely into two columns \
    column --table --table-columns-limit 2

# define docker compose commands if docker-compose.yml exists
ifeq (docker-compose.yml, $(shell ls docker-compose.yml 2>/dev/null))
docker-compose-build: # run docker compose build
> $(DOCKER_COMPOSE) build

docker-compose-down: # run docker compose down
> $(DOCKER_COMPOSE) down

docker-compose-up: # run docker compose up
> $(DOCKER_COMPOSE) up
endif

# define the custom commands from .env, without the 'COMMAND_' prefix
# eval takes its argument and evaluates it as makefile syntax
# .PHONY ensures make always runs the commands
# we pass the command through the value function to minimise expanding the command, but a secondary expansion still occurs meaning we need to know make syntax in the .env (eg $${VAR} for bash variables)
# example output:
#   .PHONY: test
#   test:
#   > echo "test"
$(foreach COMMAND, $(ENV_COMMANDS), \
  $(eval .PHONY: $(patsubst COMMAND_%,%,$(COMMAND))$(\n) \
  $(patsubst COMMAND_%,%,$(COMMAND)):$(\n)> $(value $(COMMAND))) \
)
