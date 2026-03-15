- If **no modularization opportunities** are found, document this in the report and delete the file `./next-modularization.secret` if it exists.
- If there is **only one modularization opportunity**, note that in the report `./modularization.secret`.
- If there are additional modularization opportunities beyond those listed, save them in a separate file at `./next-modularization.secret` for future remediation efforts.
- **No other files should be generated.**
- **Conduct analysis and make changes** directly in the `main` branch.
- **Implement mitigation strategies or fixes** for the identified areas.
- **Verify that the code compiles successfully.**
- **Run all relevant tests** to ensure they pass without errors.
- **Ensure the code compiles and passes linting** without issues.
- **After implementing the fixes,** re-scan the system or application to verify that modularization opportunities have been addressed.
- Do not conduct any source control management (SCM) or Git operations; these will be handled externally.
- **After implementing the fixes,** verify that all modularization issues have been resolved.
- **Conduct a detailed review** of the codebase to identify areas that can be refactored into smaller functions or modules.
- **Focus on functions or classes** that are overly complex, lengthy, or perform multiple tasks.
- **Utilize code analysis tools** (e.g., SonarQube, ESLint) to highlight potential candidates for refactoring.
For each identified area, provide the following details:
1. **Area 1: [Function/Module Name]**
   - **Description:** [Brief description of the code's purpose and its issues]
   - **Current Functionality:** [Outline what the code currently does]
   - **Suggested Breakdown:** [Propose smaller functions or modules]
2. **Area 2: [Function/Module Name]**
   - **Description:** [Brief description of the code's purpose and its issues]
   - **Current Functionality:** [Outline what the code currently does]
   - **Suggested Breakdown:** [Propose smaller functions or modules]
3. **Area 3: [Function/Module Name]**
   - **Description:** [Brief description of the code's purpose and its issues]
   - **Current Functionality:** [Outline what the code currently does]
   - **Suggested Breakdown:** [Propose smaller functions or modules]
