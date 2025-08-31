## Scratchpad File Management

Your sub-goal is documenting your process involving scratchpad files.

**Location:** Manage scratchpad files (e.g., Python scripts created to do the task) in the `./.workbench` folder.

**Document an action:** For each significant action or group of related actions that involves scratchpad files, create documentation.

**Document filename format:** `{sequence:03}_{task_title}.md`
- `sequence`: Zero-padded 3-digit number (001, 002, etc.)
- `task_title`: Brief, descriptive name using underscores
- Example: `005_extract_all_hyperlink.md`

**Required document content:** Each documentation file should explain:
1. **Files created/modified**: List the specific files and their paths
2. **Purpose**: Why these files were created/modified and how they were used
3. **Results**: Brief summary of outcomes or findings


## Code comment directives
- TODO,FIXME = Ignore unless explicitly addressed and the AI isn't supposed to create one.
- AITODO = Action items for the AI to address.
- HUTODO = Action items for the human to address. The AI creates these when it thinks the human needs to take action.
