*** Settings ***
Suite Setup            Create inputs for Rebot
Test Template          Rebot and validate RPA tasks
Resource               rebot_resource.robot

*** Variables ***
${TASKS 1}             %{TEMPDIR}${/}tasks1.xml
${TASKS 2}             %{TEMPDIR}${/}tasks2.xml
${TESTS}               %{TEMPDIR}${/}tests.xml

*** Test Cases ***
Rebot tasks
    ${EMPTY}           ${TASKS 1}               Task

Combine tasks
    ${EMPTY}           ${TASKS 1} ${TASKS 2}    Task    Failing    Passing

Merge tasks
    --merge            ${TASKS 2} ${TASKS 1}    Failing    Passing    Task=PASS:*HTML* Test added from merged output.

Rebot tests with --rpa
    --rpa              ${TESTS}                 Test
    --RPA              ${TESTS} ${TESTS}        Test    Test
    --rpa --merge      ${TESTS} ${TESTS}        Test=PASS:*HTML* Re-executed test has been merged.<hr>New status: <span class="pass">PASS</span><br>New message: <hr>Old status: <span class="pass">PASS</span><br>Old message:${SPACE}

Rebot tasks with --norpa
    [Template]    Rebot and validate test cases
    --norpa            ${TASKS 1}               Task
    --NORpa            ${TASKS 1} ${TASKS 2}    Task    Failing    Passing
    --merge --NORpa    ${TASKS 2} ${TASKS 1}    Failing    Passing    Task=PASS:*HTML* Test added from merged output.

Conflicting output files cause error
    [Template]    Rebot and validate conflict
    ${EMPTY}    ${TESTS} ${TASKS 1}               ${TASKS 1}    tasks    tests
    --merge     ${TASKS 1} ${TESTS} ${TASKS 2}    ${TESTS}      tests    tasks

Conflicking output files with --rpa are fine
    --rpa              ${TESTS} ${TASKS 1}    Test    Task
    --RPA --merge      ${TESTS} ${TASKS 1}    Test    Task=PASS:*HTML* Test added from merged output.

Conflicting output files with --norpa are fine
    [Template]    Rebot and validate test cases
    --NOrPA            ${TESTS} ${TASKS 1}    Test    Task
    --merge --norpa    ${TESTS} ${TASKS 1}    Test    Task=PASS:*HTML* Test added from merged output.

--task as alias for --test
    --task Passing    ${TASKS 2}    Passing

*** Keywords ***
Create inputs for Rebot
    Create output with Robot    ${TASKS 1}    --name "Same name to support merging"    rpa/tasks1.robot
    Create output with Robot    ${TASKS 2}    --name "Same name to support merging"    rpa/tasks2.robot
    Create output with Robot    ${TESTS}      --name "Same name to support merging"    rpa/tests.robot

Rebot and validate RPA tasks
    [Arguments]    ${options}    ${sources}    @{tasks}    &{tasks with statuses}
    Run Rebot     --log log --report report ${options}   ${sources}
    Element attribute should be    ${OUTDIR}/output.xml     rpa    true
    File should contain regexp     ${OUTDIR}/log.html       window.settings = \\{.*"rpa":true,.*\\};
    File should contain regexp     ${OUTDIR}/report.html    window.settings = \\{.*"rpa":true,.*\\};
    Should contain tests    ${SUITE}    @{tasks}    &{tasks with statuses}

Rebot and validate test cases
    [Arguments]    ${options}    ${sources}    @{tasks}    &{tasks with statuses}
    Run Rebot     --log log --report report ${options}   ${sources}
    Element attribute should be    ${OUTDIR}/output.xml     rpa    false
    File should contain regexp     ${OUTDIR}/log.html       window.settings = \\{.*"rpa":false,.*\\};
    File should contain regexp     ${OUTDIR}/report.html    window.settings = \\{.*"rpa":false,.*\\};
    Should contain tests    ${SUITE}    @{tasks}    &{tasks with statuses}

Rebot and validate conflict
    [Arguments]    ${options}    ${paths}    ${conflicting}    ${this}    ${that}
    Run Rebot without processing output    ${options}    ${paths}
    ${conflicting} =    Normalize path    ${conflicting}
    ${message} =    Catenate
    ...    [ ERROR ] Conflicting execution modes.
    ...    File '${conflicting}' has ${this} but files parsed earlier have ${that}.
    ...    Use '--rpa' or '--norpa' options to set the execution mode explicitly.
    Stderr Should Be Equal To    ${message}${USAGE TIP}\n
