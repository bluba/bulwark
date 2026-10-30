# Mod development workflow

- After completing any functionality or making any change to this mod, sync the mission files from this folder to `C:\Users\glask\Documents\bulwark` using `Sync-ToRepo.ps1`.
- Then commit the changes in that Git checkout with a clear commit message describing what was done, and push to its configured remote branch.
- The user has explicitly authorized this sync, commit, and push workflow for future mod changes; do not ask for routine confirmation. Request tool-level access only if required by the environment.
- Preserve the repository's `.git` metadata. Do not overwrite or commit unrelated user changes; inspect repository status before syncing and committing, and stage only changes belonging to the completed work.
- If syncing, committing, or pushing fails, report the failure clearly; do not claim the workflow completed.
