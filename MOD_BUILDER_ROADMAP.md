# PZ Mod Studio: A New Vision

This document outlines the plan to evolve the PZ Mod Builder into a more comprehensive, project-based application designed to support the entire modding lifecycle.

## Core Pillars

### Pillar 1: Project-Based Workflow
The Studio will manage a complete mod project folder.

*   **New Mod Wizard:** When a user creates a new mod, the tool will automatically generate the entire standard Project Zomboid directory structure (`MyMod/Contents/mods/MyMod/42/media/...`) and the necessary `mod.info` files.
*   **Project Explorer:** The main view will be a file tree of the mod's folder, allowing the user to easily navigate and manage all their files (scripts, Lua, textures, sounds, etc.).

### Pillar 2: Modular, Context-Aware Editors
Clicking on a file in the Project Explorer will open a specialized editor designed for that file type.

*   **Item/Recipe Editor:** The existing form-based editor will be retained for `.txt` script files.
*   **Lua Editor:** A proper code editor with syntax highlighting for the PZ Lua API, code completion suggestions, and error checking.
*   **Translation Editor:** A simple table-based UI for managing localization files. Users would see a grid of translation keys and columns for each language, making it easy to add and edit translations without formatting errors.
*   **Data Table Editor:** A visual, form-based editor for managing data-heavy Lua files. For example, to edit plant properties, the user would fill out a form, and the tool would generate the correct Lua code for `farming_vegetableconf.props`.

### Pillar 3: Mod-Specific Wizards and Generators
To simplify complex tasks, the Studio will include helper tools:

*   **Loot Distribution Manager:** A UI that lets users visually add their items to different in-game loot tables (e.g., "CrateFarming", "GigamartFarming") without writing Lua code.
*   **Tile & Asset Manager:** A tool to help users define custom tiles, associate them with textures, and manage their properties for in-game rendering.


## Reference Material

1. **Original game scripts:** All of the vanilla scripts are found in media/scripts directory.
2. **Project Zomboid Wiki:** Several of the instructional files from the pzwiki.net can be found in the reference directory.
3. **Sample Mods:** A couple sample mods can be found in reference/mods directory.
4. **Sqlite Database of Vanilla Project Zomboid Items:** A sqlite database of the vanilla items and recipes from scripts can be found in vanilla_database.db