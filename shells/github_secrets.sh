#!/usr/bin/env bash

yaml_eval() {
    local obj_query=$1
    local yaml_file_path="config/repositories.yaml"

    echo $(yq eval "$obj_query" $yaml_file_path)
}


github_set_secret(){
    local env_array=("$@")
    local owners_count=$(yaml_eval ".owners | length")

    for (( ow_count=0; ow_count < owners_count; ow_count++ )) do

        local owner_count_prefix=".owners[$ow_count]"
        local owner_name=$(yaml_eval "$owner_count_prefix.name")
        local repos_count=$(yaml_eval "$owner_count_prefix.repos | length")

        echo "Checking secrets for owner: $owner_name"
        for (( rp_count=0; rp_count < repos_count; rp_count++ )) do
            local repo_count_prefix="$owner_count_prefix.repos[$rp_count]"

            local repo_name=$(yaml_eval "$repo_count_prefix.name")
            local secret=$(yaml_eval "$repo_count_prefix.secret")

            if [[ "$secret" == "true" ]]; then

                echo "Found secrets to sync for git $owner_name/$repo_name"
                for env in "${env_array[@]}"; do
                    gh secret set $env --repo "$owner_name/$repo_name" --body "$env"
                done
            fi
        done
    done
}

# env_array=("test" "ooeo")
# github_set_secret "${env_array[@]}"
