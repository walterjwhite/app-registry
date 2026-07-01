#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const os = require("os");
const { execSync } = require("child_process");
const BitbucketClient = require("./bitbucketClient");
const { BitbucketAPIError } = require("./bitbucketClient");
function loadConfig() {
  const configPath = path.join(
    os.homedir(),
    ".config",
    "walterjwhite",
    "shell",
    "bitbucket-client.yaml",
  );
  const config = { auth: {} };
  try {
    if (fs.existsSync(configPath)) {
      const content = fs.readFileSync(configPath, "utf8");
      const lines = content.split(/\r?\n/);
      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith("#")) continue;
        const index = trimmed.indexOf(":");
        if (index !== -1) {
          const key = trimmed.substring(0, index).trim();
          let val = trimmed.substring(index + 1).trim();
          if (
            (val.startsWith('"') && val.endsWith('"')) ||
            (val.startsWith("'") && val.endsWith("'"))
          ) {
            val = val.substring(1, val.length - 1);
          }
          if (val && val !== "to-be-set") {
            if (key === "url") {
              config.baseUrl = val;
            } else if (["token", "username", "password"].includes(key)) {
              config.auth[key] = val;
            }
          }
        }
      }
    }
  } catch (err) {
  }
  return config;
}
function getBitbucketHost(baseUrl) {
  try {
    const url = new URL(baseUrl);
    let host = url.hostname;
    if (host === "api.bitbucket.org") {
      return "bitbucket.org";
    }
    return host;
  } catch (err) {
    return "bitbucket.org";
  }
}
const fileConfig = loadConfig();
const baseUrl = fileConfig.baseUrl || "https://api.bitbucket.org/2.0";
const bitbucketHost = getBitbucketHost(baseUrl);
const auth = {
  token: process.env.BITBUCKET_TOKEN || fileConfig.auth.token,
  username: process.env.BITBUCKET_USERNAME || fileConfig.auth.username,
  password: process.env.BITBUCKET_PASSWORD || fileConfig.auth.password,
};
function showHelp() {
  console.log(`
Bitbucket CLI Tool (bb)
Usage: bb <command> [arguments]
Commands:
  approve <pr-url>
      Approve a pull request using its full browser URL.
      Example: bb approve https://bitbucket.org/my-org/my-repo/pull-requests/12
  create-pr <repo-path-or-slug> <source-branch>:<target-branch> [title] [description]
      Create a pull request.
      If a directory path is passed (e.g. '.'), the tool automatically 
      resolves the workspace and repo slug using git remote.
      Example: bb create-pr . feature-branch:main "Add payment gate" "Dashboard payment feature description"
  merge <pr-url> [strategy] [close-branch]
      Merge a pull request.
      Strategies: merge_commit (default), squash, fast_forward
      close-branch: true (default) or false
      Example: bb merge https://bitbucket.org/my-org/my-repo/pull-requests/12 squash true
  decline <pr-url>
      Decline (cancel/close) an open pull request.
      Example: bb decline https://bitbucket.org/my-org/my-repo/pull-requests/12
  delete-branch <repo-path-or-slug> <branch-name>
      Delete a branch on the remote repository.
      Example: bb delete-branch . feature-branch
  wait-build <pr-url> [poll-interval-secs] [timeout-mins]
      Monitor and wait for the builds on the PR's source commit to complete successfully.
      Example: bb wait-build https://bitbucket.org/my-org/my-repo/pull-requests/12 15 10
  trigger-build <repo-path-or-slug> <branch-or-tag-name> [commit-hash]
      Trigger a pipeline build. To build a tag, prefix with 'tag:'.
      Example: bb trigger-build . main
      Example: bb trigger-build . tag:v1.0.0 ce5b743
  cancel-build <repo-path-or-slug> <pipeline-uuid>
      Cancel/Stop a running pipeline.
      Example: bb cancel-build . "{12345678-1234-1234-1234-1234567890ab}"
  list-comments <pr-url>
      List all comments on a pull request.
      Example: bb list-comments https://bitbucket.org/my-org/my-repo/pull-requests/12
  comment <pr-url> <comment-text>
      Add a comment to a pull request.
      Example: bb comment https://bitbucket.org/my-org/my-repo/pull-requests/12 "Code looks good!"
  delete-comment <pr-url> <comment-id>
      Delete a pull request comment.
      Example: bb delete-comment https://bitbucket.org/my-org/my-repo/pull-requests/12 9876543
  list-branches <repo-path-or-slug>
      List all branches.
      Example: bb list-branches .
  list-tags <repo-path-or-slug>
      List all tags.
      Example: bb list-tags .
  commit-info <repo-path-or-slug> <commit-sha>
      Get details about a commit.
      Example: bb commit-info . ce5b74316
  list-webhooks <repo-path-or-slug>
      List repository webhooks.
      Example: bb list-webhooks .
  create-webhook <repo-path-or-slug> <url> [events-comma-separated] [description]
      Create a repository webhook.
      Example: bb create-webhook . https://example.com/hook repo:push,pullrequest:created "My webhook"
  delete-webhook <repo-path-or-slug> <webhook-uuid>
      Delete a repository webhook.
      Example: bb delete-webhook . "{12345678-1234-1234-1234-1234567890ab}"
  repo-info <repo-path-or-slug>
      Get repository configuration and details.
      Example: bb repo-info .
  create-repo <workspace/repo-slug> [description] [is-private] [project-key]
      Create a new repository.
      Example: bb create-repo my-workspace/new-repo "Demo project" true PROJ
  delete-repo <workspace/repo-slug>
      Delete a repository (destructive).
      Example: bb delete-repo my-workspace/new-repo
Environment Variables Required:
  BITBUCKET_TOKEN                  OAuth Bearer token (preferred)
  OR
  BITBUCKET_USERNAME & BITBUCKET_PASSWORD   Basic Credentials (App Password)
`);
}
function parsePrUrl(urlStr) {
  try {
    const url = new URL(urlStr);
    const regex = /^\/([^\/]+)\/([^\/]+)\/pull-requests\/(\d+)/;
    const match = url.pathname.match(regex);
    if (
      !match ||
      (url.hostname !== bitbucketHost &&
        url.hostname !== "bitbucket.org" &&
        url.hostname !== "api.bitbucket.org")
    ) {
      throw new Error(
        "URL path does not match standard Bitbucket pull request format.",
      );
    }
    return {
      workspace: match[1],
      repoSlug: match[2],
      pullRequestId: parseInt(match[3], 10),
    };
  } catch (err) {
    console.error(`Error: Invalid Pull Request URL: "${urlStr}".`);
    console.error(
      `Expected format: https://${bitbucketHost}/{workspace}/{repo-slug}/pull-requests/{id}`,
    );
    process.exit(1);
  }
}
function resolveWorkspaceAndRepo(repoPathOrSlug) {
  if (repoPathOrSlug.includes("/") && !fs.existsSync(repoPathOrSlug)) {
    const parts = repoPathOrSlug.split("/");
    return { workspace: parts[0], repoSlug: parts[1] };
  }
  let resolvedPath = path.resolve(repoPathOrSlug);
  if (!fs.existsSync(resolvedPath)) {
    console.error(
      `Error: Repository path or slug "${repoPathOrSlug}" does not exist and is not a valid workspace/repo format.`,
    );
    process.exit(1);
  }
  try {
    const remoteUrl = execSync("git config --get remote.origin.url", {
      cwd: resolvedPath,
      encoding: "utf8",
    }).trim();
    const escapedHost = bitbucketHost.replace(/[-\/\\^$*+?.()|[\]{}]/g, "\\$&");
    const regex = new RegExp(
      `(?:${escapedHost}|bitbucket\\.org)[:/]([^/]+)/([^/\\s.]+)(?:\\.git)?$`,
    );
    const match = remoteUrl.match(regex);
    if (!match) {
      throw new Error(
        `Git remote URL "${remoteUrl}" is not a recognized Bitbucket repository (expected host: ${bitbucketHost}).`,
      );
    }
    return {
      workspace: match[1],
      repoSlug: match[2].replace(/\.git$/, ""),
    };
  } catch (err) {
    console.error(
      `Error: Could not resolve Bitbucket repository from path "${repoPathOrSlug}".`,
    );
    console.error(`Reason: ${err.message}`);
    process.exit(1);
  }
}
function checkAuth() {
  if (!auth.token && !(auth.username && auth.password)) {
    console.error("Error: Bitbucket Authentication credentials missing.");
    console.error(
      "Please export BITBUCKET_TOKEN or both BITBUCKET_USERNAME and BITBUCKET_PASSWORD.",
    );
    process.exit(1);
  }
}
async function main() {
  const args = process.argv.slice(2);
  if (args.length === 0 || ["-h", "--help", "help"].includes(args[0])) {
    showHelp();
    process.exit(0);
  }
  const command = args[0];
  try {
    switch (command) {
      case "approve": {
        const prUrl = args[1];
        if (!prUrl) {
          console.error("Error: pr-url argument is required.");
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug, pullRequestId } = parsePrUrl(prUrl);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(
          `Approving PR #${pullRequestId} in ${workspace}/${repoSlug}...`,
        );
        await client.approvePullRequest(pullRequestId);
        console.log("Success: Pull request approved.");
        break;
      }
      case "create-pr": {
        const repoSpec = args[1];
        const branchSpec = args[2];
        if (!repoSpec || !branchSpec) {
          console.error(
            "Error: both repo-path/slug and source-branch:target-branch arguments are required.",
          );
          console.error(
            "Usage: bb create-pr <repo-path-or-slug> <source>:<target> [title] [description]",
          );
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug } = resolveWorkspaceAndRepo(repoSpec);
        const parts = branchSpec.split(":");
        if (parts.length !== 2) {
          console.error(
            "Error: branch spec must be in the format <source-branch>:<target-branch>",
          );
          process.exit(1);
        }
        const [sourceBranch, destinationBranch] = parts;
        const title =
          args[3] || `PR from ${sourceBranch} to ${destinationBranch}`;
        const description = args[4] || "";
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(
          `Creating PR in ${workspace}/${repoSlug}: ${sourceBranch} -> ${destinationBranch}...`,
        );
        const pr = await client.createPullRequest({
          title,
          sourceBranch,
          destinationBranch,
          description,
        });
        console.log(`Success: Pull Request #${pr.id} created.`);
        console.log(`URL: ${pr.links.html.href}`);
        break;
      }
      case "merge": {
        const prUrl = args[1];
        if (!prUrl) {
          console.error("Error: pr-url argument is required.");
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug, pullRequestId } = parsePrUrl(prUrl);
        const mergeStrategy = args[2] || "merge_commit";
        const closeBranch = args[3] !== "false"; // defaults to true unless explicitly 'false'
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(
          `Merging PR #${pullRequestId} in ${workspace}/${repoSlug} using strategy "${mergeStrategy}"...`,
        );
        const result = await client.mergePullRequest(pullRequestId, {
          mergeStrategy,
          closeSourceBranch: closeBranch,
        });
        console.log(
          `Success: Pull request merged. State is now: ${result.state}`,
        );
        break;
      }
      case "decline": {
        const prUrl = args[1];
        if (!prUrl) {
          console.error("Error: pr-url argument is required.");
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug, pullRequestId } = parsePrUrl(prUrl);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(
          `Declining PR #${pullRequestId} in ${workspace}/${repoSlug}...`,
        );
        const result = await client.declinePullRequest(pullRequestId);
        console.log(
          `Success: Pull request declined. State is now: ${result.state}`,
        );
        break;
      }
      case "delete-branch": {
        const repoSpec = args[1];
        const branchName = args[2];
        if (!repoSpec || !branchName) {
          console.error(
            "Error: both repo-path/slug and branch-name arguments are required.",
          );
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug } = resolveWorkspaceAndRepo(repoSpec);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(
          `Deleting branch "${branchName}" from ${workspace}/${repoSlug}...`,
        );
        await client.deleteBranch(branchName);
        console.log("Success: Remote branch deleted.");
        break;
      }
      case "wait-build": {
        const prUrl = args[1];
        if (!prUrl) {
          console.error("Error: pr-url argument is required.");
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug, pullRequestId } = parsePrUrl(prUrl);
        const pollIntervalSecs = parseInt(args[2], 10) || 15;
        const timeoutMins = parseInt(args[3], 10) || 10;
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(
          `Monitoring build statuses on PR #${pullRequestId} in ${workspace}/${repoSlug}...`,
        );
        await client.waitForBuild({
          pullRequestId,
          pollIntervalMs: pollIntervalSecs * 1000,
          timeoutMs: timeoutMins * 60 * 1000,
        });
        break;
      }
      case "trigger-build": {
        const repoSpec = args[1];
        const refSpec = args[2];
        const commitHash = args[3];
        if (!repoSpec || !refSpec) {
          console.error(
            "Error: both repo-path/slug and branch/tag arguments are required.",
          );
          console.error(
            "Usage: bb trigger-build <repo-path-or-slug> <branch-or-tag> [commit-hash]",
          );
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug } = resolveWorkspaceAndRepo(repoSpec);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        let branchName = refSpec;
        let tagName = null;
        if (refSpec.startsWith("tag:")) {
          tagName = refSpec.substring(4);
          branchName = null;
        }
        console.log(
          `Triggering pipeline build on ${tagName ? `tag "${tagName}"` : `branch "${branchName}"`}${commitHash ? ` at commit ${commitHash}` : ""}...`,
        );
        const result = await client.triggerPipeline({
          branchName,
          tagName,
          commitHash,
        });
        console.log(
          `Success: Pipeline build #${result.build_number} triggered.`,
        );
        console.log(`UUID: ${result.uuid}`);
        console.log(`Status: ${result.state?.name || "INITIALIZED"}`);
        break;
      }
      case "cancel-build": {
        const repoSpec = args[1];
        const pipelineUuid = args[2];
        if (!repoSpec || !pipelineUuid) {
          console.error(
            "Error: both repo-path/slug and pipeline-uuid arguments are required.",
          );
          console.error(
            "Usage: bb cancel-build <repo-path-or-slug> <pipeline-uuid>",
          );
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug } = resolveWorkspaceAndRepo(repoSpec);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(`Cancelling pipeline build "${pipelineUuid}"...`);
        const result = await client.cancelPipeline(pipelineUuid);
        console.log(
          `Success: Pipeline stop requested. State is now: ${result.state?.name || "STOPPING"}`,
        );
        break;
      }
      case "list-comments": {
        const prUrl = args[1];
        if (!prUrl) {
          console.error("Error: pr-url argument is required.");
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug, pullRequestId } = parsePrUrl(prUrl);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(`Fetching comments for PR #${pullRequestId}...`);
        const res = await client.getPullRequestComments(pullRequestId);
        const comments = res.values || [];
        if (comments.length === 0) {
          console.log("No comments found on this pull request.");
        } else {
          console.log(`\nFound ${comments.length} comment(s):`);
          comments.forEach((c) => {
            const author = c.user?.display_name || "Unknown";
            const date = new Date(c.created_on).toLocaleString();
            const id = c.id;
            console.log(`\n[ID: ${id}] ${author} on ${date}:`);
            console.log(`  ${c.content?.raw || ""}`);
          });
        }
        break;
      }
      case "comment": {
        const prUrl = args[1];
        const text = args[2];
        if (!prUrl || !text) {
          console.error(
            "Error: both pr-url and comment-text arguments are required.",
          );
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug, pullRequestId } = parsePrUrl(prUrl);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(`Posting comment to PR #${pullRequestId}...`);
        const comment = await client.addPullRequestComment(pullRequestId, text);
        console.log(`Success: Comment posted. (Comment ID: ${comment.id})`);
        break;
      }
      case "delete-comment": {
        const prUrl = args[1];
        const commentId = args[2];
        if (!prUrl || !commentId) {
          console.error(
            "Error: both pr-url and comment-id arguments are required.",
          );
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug, pullRequestId } = parsePrUrl(prUrl);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(
          `Deleting comment ID ${commentId} on PR #${pullRequestId}...`,
        );
        await client.deletePullRequestComment(pullRequestId, commentId);
        console.log("Success: Comment deleted.");
        break;
      }
      case "list-branches": {
        const repoSpec = args[1];
        if (!repoSpec) {
          console.error("Error: repo-path/slug is required.");
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug } = resolveWorkspaceAndRepo(repoSpec);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(`Fetching branches for ${workspace}/${repoSlug}...`);
        const res = await client.getBranches();
        const branches = res.values || [];
        if (branches.length === 0) {
          console.log("No branches found.");
        } else {
          console.log("\nBranches:");
          branches.forEach((b) => console.log(`  - ${b.name}`));
        }
        break;
      }
      case "list-tags": {
        const repoSpec = args[1];
        if (!repoSpec) {
          console.error("Error: repo-path/slug is required.");
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug } = resolveWorkspaceAndRepo(repoSpec);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(`Fetching tags for ${workspace}/${repoSlug}...`);
        const res = await client.getTags();
        const tags = res.values || [];
        if (tags.length === 0) {
          console.log("No tags found.");
        } else {
          console.log("\nTags:");
          tags.forEach((t) =>
            console.log(`  - ${t.name} (Commit: ${t.target?.hash || "N/A"})`),
          );
        }
        break;
      }
      case "commit-info": {
        const repoSpec = args[1];
        const hash = args[2];
        if (!repoSpec || !hash) {
          console.error(
            "Error: both repo-path/slug and commit-sha arguments are required.",
          );
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug } = resolveWorkspaceAndRepo(repoSpec);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(`Fetching commit ${hash}...`);
        const commit = await client.getCommit(hash);
        console.log(`\nCommit: ${commit.hash}`);
        console.log(`Author: ${commit.author?.raw}`);
        console.log(`Date: ${commit.date}`);
        console.log(`Message: ${commit.message}`);
        break;
      }
      case "list-webhooks": {
        const repoSpec = args[1];
        if (!repoSpec) {
          console.error("Error: repo-path/slug is required.");
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug } = resolveWorkspaceAndRepo(repoSpec);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(`Fetching webhooks for ${workspace}/${repoSlug}...`);
        const res = await client.getWebhooks();
        const hooks = res.values || [];
        if (hooks.length === 0) {
          console.log("No webhooks registered.");
        } else {
          console.log("\nWebhooks:");
          hooks.forEach((h) => {
            console.log(
              `\n[UUID: ${h.uuid}] ${h.description || "No description"}`,
            );
            console.log(`  URL:    ${h.url}`);
            console.log(`  Active: ${h.active}`);
            console.log(`  Events: ${h.events.join(", ")}`);
          });
        }
        break;
      }
      case "create-webhook": {
        const repoSpec = args[1];
        const url = args[2];
        if (!repoSpec || !url) {
          console.error(
            "Error: both repo-path/slug and url arguments are required.",
          );
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug } = resolveWorkspaceAndRepo(repoSpec);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        const events = args[3] ? args[3].split(",") : ["repo:push"];
        const description = args[4] || "";
        console.log(
          `Creating webhook target URL ${url} on ${workspace}/${repoSlug}...`,
        );
        const hook = await client.createWebhook({ url, description, events });
        console.log(`Success: Webhook created.`);
        console.log(`UUID: ${hook.uuid}`);
        break;
      }
      case "delete-webhook": {
        const repoSpec = args[1];
        const uuid = args[2];
        if (!repoSpec || !uuid) {
          console.error(
            "Error: both repo-path/slug and webhook-uuid arguments are required.",
          );
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug } = resolveWorkspaceAndRepo(repoSpec);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(
          `Deleting webhook ${uuid} from ${workspace}/${repoSlug}...`,
        );
        await client.deleteWebhook(uuid);
        console.log("Success: Webhook deleted.");
        break;
      }
      case "repo-info": {
        const repoSpec = args[1];
        if (!repoSpec) {
          console.error("Error: repo-path/slug is required.");
          process.exit(1);
        }
        checkAuth();
        const { workspace, repoSlug } = resolveWorkspaceAndRepo(repoSpec);
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(
          `Fetching repository details for ${workspace}/${repoSlug}...`,
        );
        const repo = await client.getRepository();
        console.log(`\nRepository: ${repo.name}`);
        console.log(`Workspace:  ${repo.workspace?.name}`);
        console.log(`Project:    ${repo.project?.name} (${repo.project?.key})`);
        console.log(`Private:    ${repo.is_private}`);
        console.log(`Description:${repo.description || " None"}`);
        console.log(`Updated:    ${repo.updated_on}`);
        break;
      }
      case "create-repo": {
        const repoSpec = args[1];
        if (!repoSpec) {
          console.error("Error: workspace/repo-slug argument is required.");
          process.exit(1);
        }
        checkAuth();
        const parts = repoSpec.split("/");
        if (parts.length !== 2) {
          console.error(
            "Error: repository must be specified in the format <workspace>/<repo-slug>",
          );
          process.exit(1);
        }
        const [workspace, repoSlug] = parts;
        const description = args[2] || "";
        const isPrivate = args[3] !== "false"; // defaults to true unless explicitly 'false'
        const projectKey = args[4];
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(`Creating repository ${workspace}/${repoSlug}...`);
        const repo = await client.createRepository({
          description,
          isPrivate,
          projectKey,
        });
        console.log(`Success: Repository created.`);
        console.log(`Links: ${repo.links?.html?.href}`);
        break;
      }
      case "delete-repo": {
        const repoSpec = args[1];
        if (!repoSpec) {
          console.error("Error: workspace/repo-slug argument is required.");
          process.exit(1);
        }
        checkAuth();
        const parts = repoSpec.split("/");
        if (parts.length !== 2) {
          console.error(
            "Error: repository must be specified in the format <workspace>/<repo-slug>",
          );
          process.exit(1);
        }
        const [workspace, repoSlug] = parts;
        const client = new BitbucketClient({ workspace, repoSlug, auth });
        console.log(
          `WARNING: Deleting repository ${workspace}/${repoSlug} is destructive and cannot be undone.`,
        );
        console.log(`Deleting repository...`);
        await client.deleteRepository();
        console.log("Success: Repository deleted.");
        break;
      }
      default:
        console.error(`Error: Unknown command "${command}".`);
        showHelp();
        process.exit(1);
    }
  } catch (err) {
    if (err instanceof BitbucketAPIError) {
      console.error(`\nAPI Error (${err.status}): ${err.message}`);
      if (err.responseBody) {
        console.error("Details:", JSON.stringify(err.responseBody, null, 2));
      }
    } else {
      console.error(`\nError: ${err.message}`);
    }
    process.exit(1);
  }
}
main();
