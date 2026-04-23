# MontecarloSimulation

## Usage

* as a mix task
    - you can run `mix simulate` from the root of the repo
    - the CLI prompts for a Jira board id (to calculate velocity)
    - set these environment variables before running it:
      - `JIRA_BASE_URL` (for example `https://your-team.atlassian.net`)
      - `JIRA_EMAIL` (Jira account email)
      - `JIRA_API_TOKEN` (Jira API token)
* as a live book
    - there is a live book present in the [notebooks](./notebooks) directory
    - (warning : this may not be terribly well maintained)
