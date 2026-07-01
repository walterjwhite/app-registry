const BitbucketClient = require("./bitbucketClient");
const { BitbucketAPIError } = require("./bitbucketClient");
const config = {
  workspace: "my-workspace",
  repoSlug: "my-repository",
  auth: {
    token: process.env.BITBUCKET_TOKEN,
  },
};
const client = new BitbucketClient(config);
async function runWorkflow() {
  try {
    console.log("--- Initializing Bitbucket Pull Request Workflow ---");
    console.log("\n1. Creating Pull Request...");
    const pr = await client.createPullRequest({
      title: "feat: add awesome new feature",
      sourceBranch: "feature/awesome-ui",
      destinationBranch: "main",
      description:
        "This PR adds a premium user interface to the web application.",
    });
    console.log(`Successfully created PR #${pr.id}: ${pr.links.html.href}`);
    console.log(`\n2. Approving PR #${pr.id}...`);
    const approval = await client.approvePullRequest(pr.id);
    console.log(`Approved PR #${pr.id}.`);
    console.log(
      `\n3. Waiting for builds on PR #${pr.id} to finish successfully...`,
    );
    const statuses = await client.waitForBuild({
      pullRequestId: pr.id,
      pollIntervalMs: 10000, // check status every 10 seconds
      timeoutMs: 300000, // timeout after 5 minutes
    });
    console.log(
      `All builds passed successfully! Total statuses reported: ${statuses.length}`,
    );
    console.log(`\n4. Merging PR #${pr.id}...`);
    const mergedPr = await client.mergePullRequest(pr.id, {
      message: "Merge pull request #1 from feature/awesome-ui",
      mergeStrategy: "merge_commit", // 'merge_commit', 'squash', or 'fast_forward'
      closeSourceBranch: false, // Set false if you want to delete manually using refs API
    });
    console.log(
      `PR #${pr.id} has been merged. Current state: ${mergedPr.state}`,
    );
    console.log("\n5. Deleting source branch...");
    await client.deleteBranch("feature/awesome-ui");
    console.log("Branch feature/awesome-ui deleted successfully.");
  } catch (error) {
    if (error instanceof BitbucketAPIError) {
      console.error(`\n[BitbucketAPIError] Code: ${error.status}`);
      console.error(`Message: ${error.message}`);
      console.error("Details:", JSON.stringify(error.responseBody, null, 2));
    } else {
      console.error("\n[Error] Unexpected error in workflow:", error.message);
    }
  }
}
async function runDeclineExample() {
  try {
    console.log("\n--- Alternative: Declining (Deleting) a Pull Request ---");
    const prId = 42; // Replace with a real PR ID
    console.log(`Declining PR #${prId}...`);
    const declinedPr = await client.declinePullRequest(prId);
    console.log(
      `PR #${prId} has been declined. Current state: ${declinedPr.state}`,
    );
  } catch (error) {
    console.error("Failed to decline PR:", error.message);
  }
}
