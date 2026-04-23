# MontecarloSimulation

## Usage

* as a mix task
    - you can run `mix simulate` from the root of the repo
    - the CLI prompts for:
      - stories to deliver (must be an integer greater than 0)
      - desired release date (must be in the future, and will be rounded to the nearest Friday if needed)
      - Jira board id (to calculate velocity)
    - set these environment variables before running it:
      - `JIRA_BASE_URL` (for example `https://your-team.atlassian.net`)
      - `JIRA_EMAIL` (Jira account email)
      - `JIRA_API_TOKEN` (Jira API token)
* as a live book
    - there is a live book present in the [notebooks](./notebooks) directory
    - (warning : this may not be terribly well maintained)
