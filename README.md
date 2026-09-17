# Monte Carlo Simulations

Sometimes you want to know when your team is likely to deliver some software.

This repo provides a mix task `mix simulate` that allows running different scenarios to help you
understand when your project will finally complete.

## Usage

- you can run `mix simulate` from the root of the repo
- the CLI prompts for:
  - stories to deliver (must be an integer greater than 0)
  - desired release date (must be in the future, and will be rounded to the nearest Friday if needed)
- set these environment variables before running it:
  - `JIRA_BASE_URL` (for example `https://your-team.atlassian.net`)
  - `JIRA_EMAIL` (Jira account email)
  - `JIRA_API_TOKEN` (Jira API token)
  - `JIRA_BOARD_ID` (to calculate velocity)

## Different Scenarios

This repo comes with several different scenarios baked in, that may help you to model how your team
actually works.

- Simple
    - `MonteCarlo.Simulation.Simple`
    - assumes you deploy directly to production with CI/CD
    - assumes no bugs or regressions
- Buggy
    - `MonteCarlo.Simulation.Buggy`
    - assumes you deploy directly to production with CI/CD
    - allows configurating which percentage of work is buggy and requires re-work 
- Batched Releases
    - `MonteCarlo.Simulation.BatchRelease`
    - assumes you don't deploy directly to prod
        - can be configured for daily, weekly, or monthly batched releases
    - each release batch can either succeed or fail
    - failed releases require waiting for the next release before the work is complete

See the module docs for more details.
