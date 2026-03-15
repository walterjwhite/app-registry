- If **no unit tests** need to be generated or updated, state this in the report and remove the file, `./next-unit-tests.secret`, if it exists.
- If there is **only one unit test needing to be generated or updated**, note that in the report, `./unit-tests.secret/summary`.
- If there are additional unit tests to be generated or updated beyond those listed, document them in a separate file at `./next-unit-tests.secret` for future unit test efforts.
- No other files should be generated.
- A detailed code coverage report should be generated under, `./unit-tests.secret/`, in the appropriate format for the language (Java -> HTML (cobertura))
- Do not conduct any source control management (SCM) or Git operations; these will be managed externally.
- **Conduct analysis and make changes** directly in the `main` branch.
- **Implement mitigation strategies or fixes**
- **Verify that the code compiles successfully.**
- **Run all relevant tests** to ensure they pass without errors.
- **Ensure the code compiles and passes linting** without issues.
- **After implementing the unit tests,** re-scan the system or application to verify that unit tests have been added and increase test coverage.
- Review the existing unit tests to identify areas with low coverage.
- Use code coverage tools (e.g., Istanbul, Jacoco, Coverage.py) to generate reports and visualize coverage metrics.
- List scenarios that need to be tested to improve coverage:
  - Edge cases (inputs at boundaries)
  - Error handling scenarios (invalid inputs)
  - Critical paths in the application logic
  - User interactions and responses
- Consider both positive and negative test cases for comprehensive coverage.
- Choose an appropriate testing framework based on the programming language:
  - **JavaScript:** Jest, Mocha
  - **Python:** unittest, pytest
  - **Java:** JUnit, TestNG, Mockito
  - **C#:** NUnit, xUnit
- Implement unit tests for the identified scenarios:
- Any markdown files will be written to in the directory, `./unit-tests.secret`
1. **Test Case: [Scenario 1]**
   - Description: [Brief description of the scenario]
   - Expected Outcome: [Describe expected results]
   - Code Example:
     ```python
     def test_scenario_1():
         assert function_call(parameters) == expected_result
     ```
2. **Test Case: [Scenario 2]**
   - Description: [Brief description of the scenario]
   - Expected Outcome: [Describe expected results]
   - Code Example:
     ```python
     def test_scenario_2():
         assert function_call(parameters) == expected_result
     ```
3. **Test Case: [Scenario 3]**
   - Description: [Brief description of the scenario]
   - Expected Outcome: [Describe expected results]
   - Code Example:
     ```python
     def test_scenario_3():
         assert function_call(parameters) == expected_result
     ```
- Execute the complete suite of unit tests to ensure everything works as expected:
  ```bash
  pytest
  ```
- Run the code coverage tool again to measure the improvements and ensure that coverage has increased.
- Aim for the target coverage percentage - 80%+
- Review the added tests for quality and clarity.
