#!/usr/bin/env bash

yaml_eval() {
	local obj_query=$1
	# TODO: Don't hardcode this and pass it as an argument by github action
	local yaml_file_path="config/repositories.yaml"

	echo $(yq eval "$obj_query" $yaml_file_path)
}

set_secret() {
	local env_name=$1
	local env_value=$2
	local git_repo=$3

	gh secret set "$env_name" --repo "$git_repo" --body "$env_value"
}

set_org_level_secret() {
	local env_name=$1
	local env_value=$2
	local git_org=$3

	gh secret set "$env_name" --org "$git_org" --visibility all --body "$env_value"
}

remove_secret() {
	local env_name=$1
	local git_repo=$2

	if gh secret delete "$env_name" --repo "$git_repo" 2>/dev/null; then
		echo "Successfully deleted secret $env_name"
	else
		if [[ $? -eq 1 ]]; then
			echo "Secret $env_name not found in repo $git_repo. Skipping deletion."
		else
			echo "Failed to delete secret $env_name. Error occurred."
			exit 1
		fi
	fi
}

github_set_secret() {
	local env_name=$1
	local env_value=$2
	local owners_count=$(yaml_eval ".owners | length")

	for ((ow_count = 0; ow_count < owners_count; ow_count++)); do

		local owner_count_prefix=".owners[$ow_count]"
		local owner_name=$(yaml_eval "$owner_count_prefix.name")
		local enable_on_org_level=$(yaml_eval "$owner_count_prefix.enable_on_org_level")
		local repos_count=$(yaml_eval "$owner_count_prefix.repos | length")

		if [[ $enable_on_org_level == "true" ]]; then
			echo "Owner $owner_name has enabled org secrets!"
			set_org_level_secret "$env_name" "$env_value" "$owner_name"

		elif [[ $enable_on_org_level == "false" ]]; then
			echo "Owner $owner_name has disabled org for secret. Moving on..."
			echo "Checking secrets for owner: $owner_name"

			for ((rp_count = 0; rp_count < repos_count; rp_count++)); do
				local repo_count_prefix="$owner_count_prefix.repos[$rp_count]"

				local repo_name=$(yaml_eval "$repo_count_prefix.name")
				local secrets_enabled=$(yaml_eval "$repo_count_prefix.secrets.enable")

				if [[ $secrets_enabled == "true" ]]; then
					echo "Secrets for repo $repo_name are enabled!"

					local vars_provided=$(yaml_eval "$repo_count_prefix.secrets.variables | length")
					if [[ $vars_provided > 0 ]]; then
						local is_var_found="$(yaml_eval "$repo_count_prefix.secrets.variables | contains([\"$env_name\"])")"

						if [[ $is_var_found == "false" ]]; then
							echo "Variable $env_name is not found within the repo $repo_name . Removing now..."
							remove_secret "$env_name" "$owner_name/$repo_name"

						elif [[ $is_var_found == "true" ]]; then
							echo "Found secrets to sync for git $owner_name/$repo_name"
							set_secret "$env_name" "$env_value" "$owner_name/$repo_name"
						fi
					else
						echo "Vars for repo $repo_name are not defined. Assuming that we should import all secrets by default..."
						echo "Setting secret $env_name for repo: $repo_name"
						set_secret "$env_name" "$env_value" "$owner_name/$repo_name"
					fi
				else
					echo "Secrets for repo $repo_name are disabled! Moving on..."
				fi
			done
		fi
	done
}

for arg in "$@"; do
	IFS="=" read -r env_name env_value <<<"$arg"
	github_set_secret "$env_name" "$env_value"
done
