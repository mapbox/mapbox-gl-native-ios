#!/usr/bin/env node

const {execSync} = require('child_process');
const _ = require('lodash');

const github = require('@octokit/rest')({
  auth: `token ${process.env.GITHUB_TOKEN}`
});

const repo = {
  owner: 'mapbox',
  name: 'mapbox-gl-native-ios'
};

const GITHUB_REPO = `${repo.owner}/${repo.name}`;
const SDK_FLAVOR = process.argv[2] || process.env.SDK_FLAVOR;
const RELEASE_TAG = process.argv[3] || process.env.RELEASE_TAG;
const BRANCH_NAME = `${SDK_FLAVOR}/${RELEASE_TAG}`;
const TRAVISCI = process.env.TRAVIS ? true : false

if (!['maps', 'nav'].includes(SDK_FLAVOR) || !RELEASE_TAG) {
  console.error(`Missing arguments. Usage: \`${__filename.slice(__dirname.length + 1)} {maps|nav} {release-tag}\``);
  process.exit(1);
}

// https://developer.github.com/v3/pulls/
var pullRequest = {};

console.step = _.partial(console.log, '\033[1m\033[36m*', _, '\033[0m');

console.step(`Creating GitHub pull request for ${RELEASE_TAG} (${SDK_FLAVOR}) on ${GITHUB_REPO}`);

run();

async function run() {
  pushBranchToGitHub();

  const pullRequestExists = await checkForExistingPullRequest();
  if (!pullRequestExists) {
    await createPullRequest();
    await labelPullRequest();
  } else {
    console.log(`Skipping pull request creation. '${pullRequest.title}' by ${pullRequest.user.login} already exists at: ${pullRequest.html_url}`);
  }
}

function pushBranchToGitHub() {
  console.step(`Pushing branch '${BRANCH_NAME}' to https://github.com/${GITHUB_REPO}`);
  try {
    execSync(`git push origin HEAD:refs/heads/${BRANCH_NAME} --force`, {stdio: 'inherit'});
  } catch (error) {
    console.error('Error pushing branch to GitHub:', error);
    process.exit(1);
  }
}

async function checkForExistingPullRequest() {
  console.step('Checking for an existing and open pull request');
  try {
    const latestCommitHash = execSync(`git rev-parse HEAD`).toString().trim();
    const query = `${latestCommitHash} repo:${GITHUB_REPO} state:open type:pr`;
    console.log('Query:', query);
    const result = await github.search.issuesAndPullRequests({q: query});
    const pullRequestExists = result.data.total_count > 0;
    if (pullRequestExists) {
      // There may be multiple PRs for this branch, but let's ignore that for now.
      pullRequest = result.data.items[0];
    }
    return pullRequestExists;
  } catch (error) {
    console.error('Error checking for existing pull request:', error);
    process.exit(1);
  }
  return false;
}

async function createPullRequest() {
  console.step('Creating new pull request');
  try {
    let pullRequestBody = `API docs and site updates for [\`${RELEASE_TAG}\`](https://github.com/mapbox/${upstreamRepoForSDKFlavor()}/releases/tag/${RELEASE_TAG}).`;
    if (TRAVISCI) {
      const jobWasSuccessful = (process.env.TRAVIS_TEST_RESULT == 0 ? true : false)
      pullRequestBody += `\n\n# Travis CI Status: ${jobWasSuccessful ? '✅' : '❌'}\n` +
        `The automated [Travis CI job](${process.env.TRAVIS_JOB_WEB_URL}) that opened this pull request appears to have ${jobWasSuccessful ? 'succeeded' : 'failed — **you should double-check that the commits contain what they should and that none are missing**'}.`
    }
    const result = await github.pulls.create({
      owner: repo.owner,
      repo: repo.name,
      head: BRANCH_NAME,
      base: 'publisher-production',
      title: `[${SDK_FLAVOR}] Updates for ${RELEASE_TAG}`,
      body: pullRequestBody
    })
    if (result) {
      pullRequest = result.data;
      console.log('Created pull request:', pullRequest.html_url);
    }
  } catch (error) {
    console.error('Error creating pull request:', error);
    process.exit(1);
  }
}

async function labelPullRequest() {
  try {
    const result = await github.issues.addLabels({
      owner: repo.owner,
      repo: repo.name,
      number: pullRequest.number,
      labels: [SDK_FLAVOR, 'update']
    })
    console.log('Labeled pull request with:', result.data.map(label => label.name));
  } catch (error) {
    console.error('Error labeling pull request:', error);
    process.exit(1);
  }
}

function upstreamRepoForSDKFlavor() {
  switch(SDK_FLAVOR) {
    case 'maps': return 'mapbox-gl-native-ios'; break;
    case 'nav':  return 'mapbox-navigation-ios'; break;
    default: console.error('No upstream repo defined for SDK_FLAVOR:', SDK_FLAVOR); process.exit(1);
  }
}
