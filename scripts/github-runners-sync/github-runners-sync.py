from github import Github, Auth, GithubException
from jinja2 import Environment, FileSystemLoader
import os

# =================================================================================================
# Functions
# =================================================================================================
def create_branch_if_not_exists(repo, branch_name) -> bool:
	try:
		repo.get_branch(branch_name)
		return False
	except GithubException:
		repo.create_git_ref(ref=f"refs/heads/{branch_name}", sha=repo.get_branch("main").commit.sha)
		return True

def search_repositories(g, username, search_topics):
	if not search_topics:
		print("  - No topic specified, searching for all repositories")
		return g.search_repositories(query=f"org:{username}")

	topics_list = [search_topics] if "," not in search_topics else search_topics.split(",")
	print(f"  - Searching for repositories with topics in {topics_list}")

	runner_repos = []
	for topic in topics_list:
		repositories_for_topic = g.search_repositories(query=f"topic:{topic} org:{username}")
		print(f"  - Found {repositories_for_topic.totalCount} repositories for topic {topic}")

		runner_repos.extend(repositories_for_topic)
	return runner_repos

def create_or_update_file(repo, branch_name, file_path, file_contents):
	try:
		content = repo.get_contents(file_path, ref=branch_name)
		print(f"    - File {file_path} already exists.")

		if content.decoded_content.decode("utf-8") == file_contents:
			print("    - File contents are identical, skipping.")
			return False

		print("    - File contents are different, updating.")
		repo.update_file(
			path=file_path,
			message=f"Update runner manifest for {file_path.split('.')[0]}",
			content=file_contents,
			branch=branch_name,
			sha=content.sha
		)
	except GithubException:
		print(f"    - Creating new file {file_path}")
		repo.create_file(
			path=file_path,
			message=f"Create runner manifest for {file_path.split('.')[0]}",
			content=file_contents,
			branch=branch_name
		)

	return True

def cleanup_files(repo, branch_name, manifest_directory, runner_repos):
	try:
		existing_files = repo.get_contents(manifest_directory, ref=branch_name)

		for file in existing_files:
			repo_name = os.path.basename(file.path).split('.')[0]
			if repo_name not in runner_repos:
				print(f"  - Removing file {file_name}")
				repo.delete_file(
					path=file.path,
					message=f"Remove runner manifest for {repo_name}",
					branch=branch_name,
					sha=file.sha
				)
	except GithubException:
		print("  - No files to remove")

def create_pull_request(repo, branch_name):
	try:
		repo.create_pull(
			title="chore: update runner manifests",
			body="""
			This is an automated pull request to update runner manifests.

			---

			beep boop. I am a bot 🤖
			""".replace("\t", "")
			head=branch_name,
			base="main"
		)
		print(f"  - Pull request created")
	except GithubException as e:
		if e.data['errors'][0]['message'].startswith("A pull request already exists"):
			print("  - Pull request already exists")
		else:
			print(f"  - Error creating pull request: {e}")


# =================================================================================================
# Main
# =================================================================================================
# Extract GitHub credentials and authenticate
print("[STAGE 1] Authenticating with GitHub")
username = os.getenv("GITHUB_REPOSITORY_OWNER")
token = os.getenv("GITHUB_TOKEN")
print(f"  - Authenticating as {username}")
print(f"  - Using token {token[:4]}...{token[-4:]}")
try:
	g = Github(auth=Auth.Login(username, token))
	print("  - Authentication successful")
except GithubException:
	print("  - Authentication failed")
	exit(1)


# Fetch main GitHub repository
print("[STAGE 2] Fetching main repository")
repository = os.getenv("GITHUB_REPOSITORY")
print(f"  - Using repository {repository}")
main_repo = g.get_repo(repository)
if not main_repo:
	print("  - Repository not found")
	exit(1)
print("  - Repository found")


# Create a new branch if one doesn't already exist
print("[STAGE 3] Ensuring branch existence")
branch_name = os.getenv("SYNC_BRANCH_NAME", "chore/github-runners-sync")
print(f"  - Using branch {branch_name}")
branch_created = create_branch_if_not_exists(main_repo, branch_name)
if not branch_created:
	print("  - Branch already exists")
else:
	print("  - Branch created")


# Search for all repos with the given topic
print("[STAGE 4] Searching for repositories")
search_topics = os.getenv("SEARCH_TOPICS", None)
print(f"  - Using topics {search_topics}")
runner_repos = search_repositories(g, username, search_topics)
print(f"  - Found {len(runner_repos)} repositories")


# Template and commit the manifest file for each repo
print("[STAGE 5] Generating and commiting manifest files")
manifest_directory = os.getenv("OUTPUT_DIRECTORY")
print(f"  - Using output directory {manifest_directory}")

env = Environment(loader=FileSystemLoader("scripts/github-runners-sync/templates"))
template = env.get_template("github-runner.helm-release.yaml.j2")

files_changed = False
for repo in runner_repos:
	rendered = template.render(
		repo_owner = os.getenv("GITHUB_REPOSITORY_OWNER"),
		repo_name  = repo.name,
		repo_url = repo.clone_url
	) + "\n"

	# Create the file if it doesn't exist
	file_path = os.path.join(manifest_directory, f"{repo.name}.yaml")
	print(f"  - Processing {file_path}")
	files_changed = files_changed or create_or_update_file(main_repo, branch_name, file_path, rendered)


# Cleanup: Remove files that are not in the list of searched repositories
print("[STAGE 6] Cleaning up files")
if os.getenv("CLEANUP"):
	print("  - Cleanup enabled")
	files_changed = files_changed or cleanup_files(main_repo, branch_name, manifest_directory, runner_repos)
else:
	print("  - Skipping cleanup")

# Cleanup: Remove the branch if no files were changed
if branch_created and not files_changed:
	print("  - A new branch was created but no files were changed, deleting the branch...")
	main_repo.get_git_ref(ref=f"heads/{branch_name}").delete()
	exit(0)

# Create a pull request if one doesn't exist
print("[STAGE 7] Creating pull request")
create_pull_request(main_repo, branch_name)
