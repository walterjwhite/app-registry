const https = require("https");
const fs = require("fs");
const path = require("path");
const os = require("os");
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
class BitbucketAPIError extends Error {
  constructor(message, status, responseBody) {
    super(message);
    this.name = "BitbucketAPIError";
    this.status = status;
    this.responseBody = responseBody;
    Error.captureStackTrace(this, this.constructor);
  }
}
class BitbucketClient {
  constructor({ workspace, repoSlug, auth = {}, baseUrl } = {}) {
    if (!workspace)
      throw new Error("BitbucketClient requires a workspace parameter.");
    if (!repoSlug)
      throw new Error("BitbucketClient requires a repoSlug parameter.");
    const fileConfig = loadConfig();
    this.workspace = workspace;
    this.repoSlug = repoSlug;
    const rawBaseUrl =
      baseUrl || fileConfig.baseUrl || "https://api.bitbucket.org/2.0";
    this.baseUrl = rawBaseUrl.replace(/\/$/, "");
    this.auth = {
      token: auth.token || fileConfig.auth.token,
      username: auth.username || fileConfig.auth.username,
      password: auth.password || fileConfig.auth.password,
    };
  }
  _getHeaders() {
    const headers = {
      Accept: "application/json",
      "Content-Type": "application/json",
      "User-Agent": "Node-Bitbucket-Client",
    };
    if (this.auth.token) {
      headers["Authorization"] = `Bearer ${this.auth.token}`;
    } else if (this.auth.username && this.auth.password) {
      const credentials = Buffer.from(
        `${this.auth.username}:${this.auth.password}`,
      ).toString("base64");
      headers["Authorization"] = `Basic ${credentials}`;
    }
    return headers;
  }
  async _request(path, { method = "GET", body = null } = {}) {
    const url = `${this.baseUrl}/repositories/${this.workspace}/${this.repoSlug}${path}`;
    const headers = this._getHeaders();
    const requestOptions = { method, headers };
    if (body) {
      requestOptions.body = JSON.stringify(body);
    }
    if (typeof fetch === "function") {
      try {
        const response = await fetch(url, requestOptions);
        const text = await response.text();
        let json = null;
        if (text) {
          try {
            json = JSON.parse(text);
          } catch (e) {
            json = text;
          }
        }
        if (!response.ok) {
          const errMsg =
            json?.error?.message ||
            json ||
            `Request failed with status ${response.status}`;
          throw new BitbucketAPIError(errMsg, response.status, json);
        }
        return json;
      } catch (err) {
        if (err instanceof BitbucketAPIError) throw err;
        throw new Error(`Fetch error: ${err.message}`);
      }
    }
    return new Promise((resolve, reject) => {
      const parsedUrl = new URL(url);
      const options = {
        hostname: parsedUrl.hostname,
        port: parsedUrl.port || 443,
        path: parsedUrl.pathname + parsedUrl.search,
        method: method,
        headers: headers,
      };
      const req = https.request(options, (res) => {
        let responseData = "";
        res.on("data", (chunk) => {
          responseData += chunk;
        });
        res.on("end", () => {
          let json = null;
          if (responseData) {
            try {
              json = JSON.parse(responseData);
            } catch (e) {
              json = responseData;
            }
          }
          if (res.statusCode >= 400) {
            const errMsg =
              json?.error?.message ||
              json ||
              `Request failed with status ${res.statusCode}`;
            return reject(new BitbucketAPIError(errMsg, res.statusCode, json));
          }
          resolve(json);
        });
      });
      req.on("error", (err) => {
        reject(new Error(`HTTPS Request error: ${err.message}`));
      });
      if (body) {
        req.write(JSON.stringify(body));
      }
      req.end();
    });
  }
  async createPullRequest({
    title,
    sourceBranch,
    destinationBranch,
    description = "",
  }) {
    if (!title) throw new Error("PR title is required.");
    if (!sourceBranch) throw new Error("Source branch is required.");
    if (!destinationBranch) throw new Error("Destination branch is required.");
    const body = {
      title,
      description,
      source: {
        branch: {
          name: sourceBranch,
        },
      },
      destination: {
        branch: {
          name: destinationBranch,
        },
      },
    };
    return this._request("/pullrequests", { method: "POST", body });
  }
  async getPullRequest(pullRequestId) {
    if (!pullRequestId) throw new Error("Pull request ID is required.");
    return this._request(`/pullrequests/${pullRequestId}`);
  }
  async declinePullRequest(pullRequestId) {
    if (!pullRequestId)
      throw new Error("Pull request ID is required to decline.");
    return this._request(`/pullrequests/${pullRequestId}/decline`, {
      method: "POST",
    });
  }
  async deleteBranch(branchName) {
    if (!branchName)
      throw new Error("Branch name is required to delete a branch.");
    await this._request(`/refs/branches/${encodeURIComponent(branchName)}`, {
      method: "DELETE",
    });
    return true;
  }
  async mergePullRequest(
    pullRequestId,
    {
      message = "",
      mergeStrategy = "merge_commit",
      closeSourceBranch = true,
    } = {},
  ) {
    if (!pullRequestId)
      throw new Error("Pull request ID is required to merge.");
    const body = {
      close_source_branch: closeSourceBranch,
      merge_strategy: mergeStrategy,
    };
    if (message) {
      body.message = message;
    }
    return this._request(`/pullrequests/${pullRequestId}/merge`, {
      method: "POST",
      body,
    });
  }
  async approvePullRequest(pullRequestId) {
    if (!pullRequestId)
      throw new Error("Pull request ID is required to approve.");
    return this._request(`/pullrequests/${pullRequestId}/approve`, {
      method: "POST",
    });
  }
  async getCommitStatuses(commitHash) {
    if (!commitHash)
      throw new Error("Commit hash is required to fetch build statuses.");
    return this._request(`/commit/${commitHash}/statuses`);
  }
  async waitForBuild({
    commitHash,
    pullRequestId,
    pollIntervalMs = 15000,
    timeoutMs = 600000,
  }) {
    let targetHash = commitHash;
    if (!targetHash) {
      if (!pullRequestId) {
        throw new Error(
          "Either commitHash or pullRequestId must be provided to waitForBuild.",
        );
      }
      console.log(
        `[BitbucketClient] Fetching PR #${pullRequestId} details to determine target commit hash...`,
      );
      const prDetails = await this.getPullRequest(pullRequestId);
      targetHash = prDetails.source?.commit?.hash;
      if (!targetHash) {
        throw new Error(
          `Could not determine source commit hash for pull request #${pullRequestId}`,
        );
      }
      console.log(
        `[BitbucketClient] Monitoring builds on source commit hash: ${targetHash}`,
      );
    }
    const startTime = Date.now();
    while (true) {
      if (Date.now() - startTime > timeoutMs) {
        throw new Error(
          `Timeout waiting for builds to complete on commit ${targetHash}`,
        );
      }
      console.log(
        `[BitbucketClient] Fetching build statuses for commit ${targetHash}...`,
      );
      const statusResponse = await this.getCommitStatuses(targetHash);
      const statuses = statusResponse.values || [];
      if (statuses.length === 0) {
        console.log(
          "[BitbucketClient] No build statuses reported yet. Retrying...",
        );
      } else {
        const inProgress = statuses.filter((s) => s.state === "INPROGRESS");
        const failed = statuses.filter(
          (s) => s.state === "FAILED" || s.state === "STOPPED",
        );
        const successful = statuses.filter((s) => s.state === "SUCCESSFUL");
        console.log(
          `[BitbucketClient] Status: ${successful.length} successful, ${inProgress.length} in-progress, ${failed.length} failed/stopped.`,
        );
        if (failed.length > 0) {
          const failedDetails = failed
            .map((s) => `${s.name || s.key}: ${s.state}`)
            .join(", ");
          throw new Error(
            `Build verification failed on commit ${targetHash}. Failures: ${failedDetails}`,
          );
        }
        if (inProgress.length === 0 && successful.length > 0) {
          console.log("[BitbucketClient] All builds completed successfully!");
          return statuses;
        }
      }
      await new Promise((resolve) => setTimeout(resolve, pollIntervalMs));
    }
  }
  async triggerPipeline({ branchName, tagName, commitHash } = {}) {
    if (!branchName && !tagName) {
      throw new Error(
        "Either branchName or tagName is required to trigger a pipeline.",
      );
    }
    const body = {
      target: {
        type: "pipeline_ref_target",
        ref_type: branchName ? "branch" : "tag",
        ref_name: branchName || tagName,
      },
    };
    if (commitHash) {
      body.target.commit = {
        type: "commit",
        hash: commitHash,
      };
    }
    return this._request("/pipelines/", { method: "POST", body });
  }
  async cancelPipeline(pipelineUuid) {
    if (!pipelineUuid)
      throw new Error("Pipeline UUID is required to cancel a pipeline.");
    const encodedUuid = encodeURIComponent(pipelineUuid);
    return this._request(`/pipelines/${encodedUuid}/stopPipeline/`, {
      method: "POST",
    });
  }
  async getPullRequestComments(pullRequestId) {
    if (!pullRequestId)
      throw new Error("Pull request ID is required to fetch comments.");
    return this._request(`/pullrequests/${pullRequestId}/comments`);
  }
  async addPullRequestComment(pullRequestId, text) {
    if (!pullRequestId)
      throw new Error("Pull request ID is required to add a comment.");
    if (!text) throw new Error("Comment text is required.");
    const body = {
      content: {
        raw: text,
      },
    };
    return this._request(`/pullrequests/${pullRequestId}/comments`, {
      method: "POST",
      body,
    });
  }
  async deletePullRequestComment(pullRequestId, commentId) {
    if (!pullRequestId)
      throw new Error("Pull request ID is required to delete a comment.");
    if (!commentId)
      throw new Error("Comment ID is required to delete a comment.");
    await this._request(
      `/pullrequests/${pullRequestId}/comments/${commentId}`,
      { method: "DELETE" },
    );
    return true;
  }
  async getBranches() {
    return this._request("/refs/branches");
  }
  async getTags() {
    return this._request("/refs/tags");
  }
  async getCommit(commitHash) {
    if (!commitHash) throw new Error("Commit hash is required.");
    return this._request(`/commit/${commitHash}`);
  }
  async getWebhooks() {
    return this._request("/hooks");
  }
  async createWebhook({
    url,
    description = "",
    events = ["repo:push"],
    active = true,
  }) {
    if (!url) throw new Error("Webhook URL is required.");
    const body = {
      url,
      description,
      events,
      active,
    };
    return this._request("/hooks", { method: "POST", body });
  }
  async deleteWebhook(webhookUuid) {
    if (!webhookUuid) throw new Error("Webhook UUID is required.");
    const encodedUuid = encodeURIComponent(webhookUuid);
    await this._request(`/hooks/${encodedUuid}`, { method: "DELETE" });
    return true;
  }
  async getRepository() {
    return this._request("");
  }
  async createRepository({
    description = "",
    isPrivate = true,
    projectKey,
  } = {}) {
    const body = {
      scm: "git",
      is_private: isPrivate,
      description,
    };
    if (projectKey) {
      body.project = { key: projectKey };
    }
    return this._request("", { method: "POST", body });
  }
  async deleteRepository() {
    await this._request("", { method: "DELETE" });
    return true;
  }
}
module.exports = BitbucketClient;
module.exports.BitbucketAPIError = BitbucketAPIError;
