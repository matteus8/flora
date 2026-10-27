# Custom Staq (staq-custom)

Template for cherry-picking specific components for a bespoke Platform STAQ deployment.

## Usage

Mix and match components from `01-staq-core`, `02a-staq-gitlab`, `02b-staq-factory`, and `03-staq-ide` by importing their component paths into `zarf.yaml`.

> **Note:** Be mindful of resource constraints and package artifact sizes when combining large components into a single package.
