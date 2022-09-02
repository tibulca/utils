YELLOW='\033[1;33m'
GREEN='\033[0;32m'
LIGHT_GREEN='\033[1;32m'
NO_COLOR='\033[0m'

printCmd () {
	echo "  ${GREEN}$1${NO_COLOR}"
}

evalCmdNoPrompt () {
	echo "  exec: ${GREEN}$1${NO_COLOR}"
	eval "$1"
}

evalCmd () {
	echo "  exec: ${GREEN}$1${NO_COLOR}\n  <hit enter to continue>"
	read dummy
	eval "$1"
}

reload () {
	evalCmdNoPrompt "source ~/.zshrc"
}

setEnvVar () {
	evalCmdNoPrompt "export \"$1\"=\"$2\""
}

#############################################
#   GIT
#############################################
git-sign-until-master () {
	evalCmd "git rebase --exec 'git commit --amend --no-edit -n -S' -i master"
}

git-ammend () {
	evalCmdNoPrompt "git commit --amend --no-edit -n -S"
}

git-stage-all () {
	evalCmdNoPrompt "git add ."
}

git-branch () {
	if [ -z "$1" ]
	then
		echo "usage: git-branch <name>"
	else
		evalCmdNoPrompt "git branch $1"
		evalCmdNoPrompt "git switch $1"
	fi
}

git-reset-hard () {
	evalCmdNoPrompt "git reset --hard"
	evalCmdNoPrompt "git clean -d -n"
	evalCmd "git clean -df"
}

git-checkout () {
	if [ -z "$1" ]
	then
		echo "usage: git-checkout <name>"
	else
		evalCmdNoPrompt "git checkout $1"
		evalCmdNoPrompt "git pull origin $1"
	fi	
}

git-rebase-master () {
	evalCmdNoPrompt "CURRENT_BRANCH=$(git branch --show-current)"
	evalCmdNoPrompt "git switch master"
	evalCmdNoPrompt "git pull"
	evalCmdNoPrompt "git switch $CURRENT_BRANCH"
	evalCmdNoPrompt "git rebase master"
}

#############################################
#   OPS MANAGER K8S
#############################################

om () {
	evalCmdNoPrompt "cd ~/repos/ops-manager-kubernetes"
}

om-e2e () {
	om
	evalCmd "make e2e test=$1 light=true"
}

om-edit () {
	evalCmd "k edit om ops-manager"
}

om-evergreen-e2e () {
	evalCmd "evergreen patch -p ops-manager-kubernetes -v e2e_om50_kind_ubi -t $1 -f -y -d \"Full run\" -u --browse"
}

#############################################
#   K8S
#############################################

k-ctx () {
	echo "current context:"
	evalCmdNoPrompt "kubectl config get-contexts"

	echo -n "\n\nnew context: "
	read ctx
	evalCmd "kubectl config use-context $ctx"
}

k-ns () {
	echo "current context namespace:"
	evalCmdNoPrompt "k config view -o jsonpath='{.contexts[?(@.context.cluster == \"$(k config current-context)\")].context.namespace}'"

	echo -n "\n\nnew context namespace:"
	read ns
	evalCmd "k config set-context --current --namespace=$ns"
}

k-cluster-config () {
	evalCmd "k config view --minify --raw"
}

k-get-all-crs () {
	#evalCmd 'k get crd -o json | jq ".items[].metadata.name" | xargs -L1 kubectl get'

	echo "${GREEN} --- exec: kubectl get crd -o json | jq '.items[].metadata.name' | xargs -L1 sh -c 'for arg do echo \"___CRD: $1___\"; kubectl get $1; done' _${NO_COLOR}"
	kubectl get crd -o json | jq '.items[].metadata.name' | xargs -L1 sh -c 'for arg do echo "___CRD: $1___"; kubectl get $1; done' _
}

k-bash-pod () {
	evalCmd "echo '    CONTAINERS:' && k get pod $1 -o jsonpath='{.spec.containers[*].name}'"
	echo '\n    select container: '
	read c
	evalCmd "k exec -it $1 -c $c bash"
}

#############################################
#   DOCKER
#############################################


d-clean-images () {
	evalCmd "docker rmi $(docker images -a --filter=dangling=true -q)"
}

d-clean-ps () {
	evalCmd "docker rm $(docker ps --filter=status=exited --filter=status=created -q)"
}

d-prune () {
	evalCmd "docker system prune -a"
}

d-size () {
	evalCmd "docker system df -v"
}

d-logins () {
	evalCmd "sublime ~/.docker/config.json"
}

############################################

s () {
	evalCmdNoPrompt "ssh-add -K ~/.ssh/id_ed25519"
}

zsh-config () {
	evalCmdNoPrompt "sublime ~/.zshrc"
}

p3-setup-local () {
	evalCmdNoPrompt "python -m venv venv"
	evalCmdNoPrompt "source venv/bin/activate"
}

############################################
# gcloud

gcloud-defaults () {
	evalCmdNoPrompt "gcloud config get-value project"
	echo "to set: gcloud config set project <project id>\n"
	evalCmdNoPrompt "gcloud config get-value compute/zone"
	evalCmdNoPrompt "gcloud config get-value compute/region"

	echo "\nuseful commands:"
	echo "  gcloud auth login"
	echo "  gcloud compute zones list"
	echo "  gcloud container clusters get-credentials citi"
}

############################################


alias k='kubectl'
alias kd='kubectl describe'
alias kg='kubectl get'
alias kwa='watch k get all,secrets,role,sa,crd,cm'
alias p3='python3'

alias watch='watch -n 1 '

alias python="python3"
alias pip="pip3"

############################################
# mms

mms () {
	evalCmdNoPrompt "cd ~/repos/mms"
}

mms-evg () {
	mms
	evalCmd "evergreen patch -p mms -y -d 'test patch' -v code_health -u"
}

mms-e2e () {
	mms-evg
}

mms-start-db () {
	mms
	evalCmdNoPrompt "./scripts/mongodb-start-standalone.bash"
}

mms-init-atlas () {
	mms
	echo "  *** THIS SHOULD RUN ONLY TO INIT ATLAS CONF! ***"
	evalCmd "bazel run //server:mms_init_local"
}

mms-build-client () {
	mms
	cd client
	evalCmdNoPrompt "npm i"
	evalCmdNoPrompt "npm run init"
}

mms-run-atlas () {
	mms
	echo "  might require:"
	echo "    1. mms-build-client"
	echo "    2. mms-start-db"
	echo "    3. mms-init-atlas"
	evalCmd "bazel run //server:mms_skip_assets"
}

mms-run-om () {
	mms
	evalCmd "bazel run --server_env=hosted //server:mms"
}

mms-run-om-50 () {
	mms
	evalCmd "bazel run //server:om"
}

mms-run-backup-daemon () {
	mms
	evalCmd "bazel run //server:daemon"
}

mms-reset () {
	mms
	evalCmd "bazel run //server:mms_reset_local"
}

mms-format-java () {
	mms
	evalCmd 'bazel run //scripts:format_java_file -- "*.java"'
}

mms-integration-tests () {
	mms
	evalCmd "evergreen patch -p mms -y -d 'Debug Integration Tests Patch $(date +%Y.%m.%d-%H:%M)' -v bazel_linux_x86_64 -u -f --browse -t GENERATE_INT_TESTS_BAZEL"
}


mms-openapi-gen-spec () {
	mms
	echo "check https://wiki.corp.mongodb.com/display/DE/Adding+Swagger-Core+%28OpenAPI%29+Annotations+to+mms"
	evalCmd "evergreen patch -p mms -v e2e_local -t E2E_OpenAPI_GenerateSpec -y -u -f -d 'Sanity check for OpenAPI Spec Generation'"
}

mms-ngrok () {
	evalCmd "ngrok http --subdomain=mongodb-cloud-ciprian-tibulca 8080"
}

mms-lint-bazel () {
	mms
	echo "\nbased on: ./scripts/buildifier_format_all -mode check -lint warn -warnings=-positional-args\n"
	evalCmdNoPrompt "cd client"
	evalCmd "find \"..\" \\( -name BUILD -or -name BUILD.bazel -or -name WORKSPACE -or -name \"*.bzl\" \\) ! -path \"*/node_modules/*\" ! -path \"*/out/*\" ! -path \"*/server/scripts/bazel/junit.bzl\" -exec /Users/ciprian.tibulca/.asdf/installs/golang/1.18/packages/bin/buildifier -mode check -lint warn -warnings=-positional-args \"{}\" +"
}

############################################
# mongocli

cli () {
	evalCmdNoPrompt "cd ~/repos/mongodb-atlas-cli"
}

alias atlasdev="~/repos/mongocli/bin/atlas"

cli-lint () {
	cli
	evalCmdNoPrompt "golangci-lint run --fix --timeout 5m"
}

cli-atlas-config () {
	cli
	evalCmdNoPrompt "sublime '/Users/ciprian.tibulca/Library/Application Support/atlascli/config.toml'"
}

cli-config () {
	cli
	evalCmdNoPrompt "sublime '/Users/ciprian.tibulca/Library/Application Support/mongocli/config.toml'"
}

cli-atlas-build () {
	cli
	evalCmdNoPrompt "make build-atlascli"
}

cli-build () {
	cli
	evalCmdNoPrompt "make build"
}

cli-config-dev () {
	cli
	evalCmdNoPrompt "MCLI_OPS_MANAGER_URL=https://cloud-dev.mongodb.com/ ./bin/mongocli config -P dev"
}

cli-test () {
	cli
	if [ -z "$1" ]
	then
	      printCmd "path is missing, example usage: cli-test ./internal/cli/auth..."
	else
	      evalCmdNoPrompt "go test --tags=unit -race -cover -count=1 $1"
	fi
}

