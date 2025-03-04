# Landing zone for git repositories

## Abstract 🚀

This project serves as a central location for managing multiple repositories/organizations.
The managmenet of new and exisitng repos is done mainly via github action and the desired state of the accounts are defined inside the `config` directory of the project.

## Available features 🧪

1. Synchronize repo secrets

## Project structure 🏗️ 

```markdown
.
├── config
├── flake.nix
├── LICENSE
├── README.md
└── shells

```

- **config**: Directory, containing the desired state of the member repositories. Example include synchronizing secrets for the repos
- **flake.nix**: Development environment for testing features locally before pushing it remotely  
- **shells**: Directory for defining the core logic for the github actions to perform the repo synchronization 

## Used technologies 🧑‍💻 

- **yq**: For querying and manipulating yaml files on the config directory


### 📃 License
This product is licensed under [GNU General Public License](https://www.gnu.org/licenses/gpl-3.0.en.html)
