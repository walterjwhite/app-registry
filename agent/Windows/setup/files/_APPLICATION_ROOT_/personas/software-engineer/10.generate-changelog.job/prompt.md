- If **no changes** are found, state this in the report.
- If there is **only one change**, note that in the report, `./changelog.secret`.
- No other files should be generated.
- Do not conduct any source control management (SCM) or Git operations; these will be managed externally.
- **Conduct analysis and make changes** directly in the `main` branch.
- **Do not make any changes to source code**
- **Only generate or update the file, `./changelog.secret`**
- **After implementing the fixes,** re-scan the application or system to verify that tight coupling issues have been addressed.
Create a summary of all changes since the last production deployment. Classify each item as a feature, bug fix, vulnerability fix, or other relevant categories, and specify the affected components.
1. **Identify Changes:**
   - Gather all changes made since the last production deployment, including features, bug fixes, and vulnerability fixes.
2. **Categorize Changes:**
   - For each change, classify it as one of the following:
     - **Feature:** A new capability or improvement added to the system.
     - **Bug Fix:** Changes made to resolve an error or issue affecting the system.
     - **Vulnerability Fix:** Updates aimed at addressing security vulnerabilities.
     - **Other:** Any miscellaneous changes that do not fall into the above categories.
3. **Specify Affected Components:**
   - Identify which components are impacted by each change. This may include modules, services, or specific functionalities.
4. **Format the Summary:**
   - Present the summary in a clear and organized manner. Use the following structure:
| Change Type           | Description                            | Affected Components           | Reference/Issue Number (if applicable) |
| --------------------- | -------------------------------------- | ----------------------------- | -------------------------------------- |
| **Feature**           | [Description of the new feature]       | [List of affected components] | #[Issue Number]                        |
| **Bug Fix**           | [Description of the bug fix]           | [List of affected components] | #[Issue Number]                        |
| **Vulnerability Fix** | [Description of the vulnerability fix] | [List of affected components] | #[Issue Number]                        |
| **Other**             | [Description of any other changes]     | [List of affected components] | #[Issue Number]                        |
5. **Review:**
   - Ensure that all changes are accurately classified, described, and have their affected components listed.
   - Double-check for any missing items or discrepancies.
6. **Output the Summary:**
   - Present the final summary in a concise format suitable for inclusion in deployment documentation or communication to stakeholders.
