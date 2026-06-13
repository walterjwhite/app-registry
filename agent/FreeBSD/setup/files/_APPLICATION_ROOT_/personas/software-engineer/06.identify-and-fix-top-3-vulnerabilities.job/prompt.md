- If **no CVEs** are found, state this in the report and remove the file, `./next-vulnerabilities.secret`, if it exists.
- If there is **only one CVE**, note that in the report, `./vulnerabilities.secret`.
- If there are additional CVEs beyond those listed, document them in a separate file at `./next-vulnerabilities.secret` for future remediation efforts.
- No other files should be generated.
- Do not conduct any source control management (SCM) or Git operations; these will be managed externally.
- **Conduct analysis and make changes** directly in the `main` branch.
- **Implement mitigation strategies or fixes**
- **Verify that the code compiles successfully.**
- **Run all relevant tests** to ensure they pass without errors.
- **Ensure the code compiles and passes linting** without issues.
- **After implementing the fixes,** re-scan the system or application to verify that vulnerabilities have been resolved.
- **Assess** the application or system for potential vulnerabilities.
- **Utilize security scanning tools** (e.g., OWASP ZAP, Nessus) to identify known vulnerabilities.
- **Conduct a manual review** of the code and system configurations.
For vulnerabilities rated **low**:
- Document them in a separate findings report, including the risk level and affected components.
- Save the report as a markdown file at `./vulnerabilities.secret`.
For each medium or high vulnerability, provide the following details:
1. **Vulnerability Name 1**
   - **Description:** [Brief description]
   - **Risk Level:** [Medium/High]
   - **Affected Components:** [Specify components or code sections]
2. **Vulnerability Name 2**
   - **Description:** [Brief description]
   - **Risk Level:** [Medium/High]
   - **Affected Components:** [Specify components or code sections]
3. **Vulnerability Name 3**
   - **Description:** [Brief description]
   - **Risk Level:** [Medium/High]
   - **Affected Components:** [Specify components or code sections]
