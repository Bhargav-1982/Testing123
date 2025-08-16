#!/bin/bash
# autograder.sh - Simple but comprehensive autograder for C assignments
set -e  # Exit on any error

# Configuration
TIMEOUT_SECONDS=5
COMPILATION_POINTS=20
TEST_POINTS=80
TOTAL_POINTS=100

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Initialize scores
COMPILATION_SCORE=0
TEST_SCORE=0
TOTAL_TESTS=0
PASSED_TESTS=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Hands On GitHub: Your first assignment${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Student: $GITHUB_ACTOR"
echo "Repository: $GITHUB_REPOSITORY"
echo "Submission time: $(date)"
echo

# Create results directory
mkdir -p AUTOGRADER_TEST_RESULTS

# Function to log results
log_result() {
    echo "$1" | tee -a AUTOGRADER_TEST_RESULTS/detailed_log.txt
}

# Step 1: Check required files
echo -e "${BLUE}=== Step 1: Checking Required Files ===${NC}"
if [[ ! -f "student_solution.c" ]]; then
    echo -e "${RED}❌ ERROR: student_solution.c not found!${NC}"
    echo "Please make sure your C file is named exactly 'student_solution.c'"
    log_result "CRITICAL ERROR: student_solution.c missing"
    exit 1
fi

if [[ ! -f "Makefile" ]]; then
    echo -e "${RED}❌ ERROR: Makefile not found!${NC}"
    log_result "CRITICAL ERROR: Makefile missing"
    exit 1
fi

echo -e "${GREEN}✅ All required files found${NC}"
log_result "✅ Required files check: PASSED"

# Step 2: Compilation
echo -e "${BLUE}=== Step 2: Compilation ===${NC}"

# Clean any previous builds
if make clean >/dev/null 2>&1; then
    echo "Cleaned previous build files"
fi

# Compilation
echo "Attempting compilation..."
if make > compilation.log 2>&1; then
    echo -e "${YELLOW}☑️  Compilation successful...${NC}"
    COMPILATION_SCORE=$((COMPILATION_POINTS * 4 / 5))      
else
    echo -e "${RED}❌ Compilation faile...d${NC}"
    echo "Compilation errors:"
    cat compilation.log
    COMPILATION_SCORE=0
    log_result "COMPILATION FAILED"
    log_result "Errors:"
    cat compilation.log >> AUTOGRADER_TEST_RESULTS/detailed_log.txt
    
    # Create summary and exit
    {
        echo "FINAL_SCORE: 0"
        echo "TOTAL_POSSIBLE: $TOTAL_POINTS"
        echo "COMPILATION: FAILED"
        echo "REASON: Compilation errors"
    } > AUTOGRADER_TEST_RESULTS/summary.txt
    exit 1
fi

# Verify executable was created
if [[ ! -f "calc" ]]; then
    echo -e "${RED}❌ ERROR: Executable 'calc' not created${NC}"
    log_result "ERROR: No executable produced"
    exit 1
fi

log_result "Compilation: $COMPILATION_SCORE/$COMPILATION_POINTS"

# Step 3: Testing
echo -e "${BLUE}=== Step 3: Running Test Cases ===${NC}"

# Check if tests directory exists
if [[ ! -d "tests" ]]; then
    echo -e "${RED}❌ ERROR: tests/ directory not found${NC}"
    log_result "ERROR: No tests directory"
    exit 1
fi

# Find all test cases
TEST_INPUTS=(tests/Testcases/input*.txt)
if [[ ${#TEST_INPUTS[@]} -eq 0 ]] || [[ ! -f "${TEST_INPUTS[0]}" ]]; then
    echo -e "${RED}❌ ERROR: No test cases found${NC}"
    log_result "ERROR: No test cases"
    exit 1
fi

TOTAL_TESTS=${#TEST_INPUTS[@]}
echo "Found $TOTAL_TESTS test case(s)"

# Run each test
for input_file in "${TEST_INPUTS[@]}"; do
    if [[ ! -f "$input_file" ]]; then
        continue
    fi
    
    # Extract test number
    test_name=$(basename "$input_file" .txt)
    test_num=${test_name#input}
    expected_file="tests/Expected_Output/output${test_num}.txt"
    
    echo -e "${BLUE}--- Test $test_num ---${NC}"
    
    # Check if expected output exists
    if [[ ! -f "$expected_file" ]]; then
        echo -e "${RED}❌ Expected output file missing: $expected_file${NC}"
        log_result "Test $test_num: MISSING EXPECTED OUTPUT"
        continue
    fi
    
    # Show what we're testing
    echo "Input:"
    cat "$input_file" | sed 's/^/  /'
    echo "Expected output:"
    cat "$expected_file" | sed 's/^/  /'
    
    # Run the test
    student_output="AUTOGRADER_TEST_RESULTS/student_output_${test_num}.txt"
    
    if timeout $TIMEOUT_SECONDS ./cal < "$input_file" > "$student_output" 2>/dev/null; then
        # Compare outputs (ignore trailing whitespace)
        if diff -w -B "$expected_file" "$student_output" > "AUTOGRADER_TEST_RESULTS/diff_${test_num}.txt" 2>&1; then
            echo -e "${GREEN}✅ Test $test_num: PASSED${NC}"
            log_result "Test $test_num: PASSED"
            ((PASSED_TESTS++))
        else
            echo -e "${RED}❌ Test $test_num: FAILED (incorrect output)${NC}"
            echo "Your output:"
            cat "$student_output" | sed 's/^/  /'
            echo "Difference:"
            head -n 5 "AUTOGRADER_TEST_RESULTS/diff_${test_num}.txt" | sed 's/^/  /'
            log_result "Test $test_num: FAILED (incorrect output)"
        fi
    else
        echo -e "${RED}❌ Test $test_num: FAILED (timeout or crash)${NC}"
        log_result "Test $test_num: FAILED (timeout/crash)"
    fi
    echo
done

# Calculate test score
if [[ $TOTAL_TESTS -gt 0 ]]; then
    TEST_SCORE=$((PASSED_TESTS * TEST_POINTS / TOTAL_TESTS))
else
    TEST_SCORE=0
fi

log_result "Testing: $TEST_SCORE/$TEST_POINTS ($PASSED_TESTS/$TOTAL_TESTS passed)"

# Step 5: Calculate final score
echo -e "${BLUE}=== Final Results ===${NC}"


if [[ $FINAL_SCORE -lt 0 ]]; then
    FINAL_SCORE=0
fi

# Display results
echo "┌─────────────────────────────────────┐"
echo "│           GRADE BREAKDOWN           │"
echo "├─────────────────────────────────────┤"
printf "│ Compilation:      %3d/%3d points   │\n" $COMPILATION_SCORE $COMPILATION_POINTS
printf "│ Test Cases:       %3d/%3d points   │\n" $TEST_SCORE $TEST_POINTS
echo "├─────────────────────────────────────┤"
printf "│ Subtotal:         %3d/%3d points   │\n" $SUBTOTAL $TOTAL_POINTS


echo "├─────────────────────────────────────┤"
printf "│ FINAL SCORE:      %3d/%3d points   │\n" $FINAL_SCORE $TOTAL_POINTS
printf "│ PERCENTAGE:           %3d%%          │\n" $((FINAL_SCORE * 100 / TOTAL_POINTS))
echo "└─────────────────────────────────────┘"

# Create machine-readable summary
{
    echo "FINAL_SCORE: $FINAL_SCORE"
    echo "TOTAL_POSSIBLE: $TOTAL_POINTS"
    echo "PERCENTAGE: $PERCENTAGE"
    echo "LETTER_GRADE: $LETTER_GRADE"
    echo "COMPILATION_SCORE: $COMPILATION_SCORE"
    echo "TEST_SCORE: $TEST_SCORE"
    echo "STYLE_SCORE: $STYLE_SCORE"
    echo "TESTS_PASSED: $PASSED_TESTS"
    echo "TOTAL_TESTS: $TOTAL_TESTS"
    echo "LATE_PENALTY: $LATE_PENALTY"
    echo "TIMESTAMP: $(date -u)"
    echo "STUDENT: $GITHUB_ACTOR"
    echo "REPOSITORY: $GITHUB_REPOSITORY"
    echo "COMMIT: $GITHUB_SHA"
} > AUTOGRADER_TEST_RESULTS/summary.txt

log_result "=== FINAL SUMMARY ==="
log_result "Score: $FINAL_SCORE/$TOTAL_POINTS ($PERCENTAGE%)"
log_result "Grade: $LETTER_GRADE"
log_result "Tests passed: $PASSED_TESTS/$TOTAL_TESTS"

echo
echo "Detailed results saved to AUTOGRADER_TEST_RESULTS/ directory"
echo "Summary available in AUTOGRADER_TEST_RESULTS/summary.txt"

# Exit with appropriate code for GitHub Actions
if [[ $FINAL_SCORE -ge $((TOTAL_POINTS * 6 / 10)) ]]; then
    echo -e "${GREEN}🎉 Congratulations! Assignment completed successfully.${NC}"
    exit 0
else
    echo -e "${YELLOW}📚 Assignment needs improvement. Keep working on it!${NC}"
    exit 1
fi