#!/bin/bash
# autograder.sh - Simple but comprehensive autograder for C assignments

set -e  # Exit on any error

# Configuration
TIMEOUT_SECONDS=5
COMPILATION_POINTS=15
TEST_POINTS=80
STYLE_POINTS=5
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
STYLE_SCORE=0
TOTAL_TESTS=0
PASSED_TESTS=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    C Programming Assignment Autograder${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Student: $GITHUB_ACTOR"
echo "Repository: $GITHUB_REPOSITORY"
echo "Submission time: $(date)"
echo

# Create results directory
mkdir -p test_results

# Function to log results
log_result() {
    echo "$1" | tee -a test_results/detailed_log.txt
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

# Step 2: Basic code quality check
echo -e "${BLUE}=== Step 2: Code Quality Check ===${NC}"

# Check file size (reasonable limits)
FILE_SIZE=$(wc -c < student_solution.c)
if [[ $FILE_SIZE -gt 10000 ]]; then
    echo -e "${YELLOW}⚠️  Warning: Large file size (${FILE_SIZE} bytes)${NC}"
elif [[ $FILE_SIZE -lt 50 ]]; then
    echo -e "${YELLOW}⚠️  Warning: Very small file size (${FILE_SIZE} bytes)${NC}"
else
    echo -e "${GREEN}✅ File size looks reasonable (${FILE_SIZE} bytes)${NC}"
fi

# Check for basic required elements
STYLE_ISSUES=0

if ! grep -q "#include" student_solution.c; then
    echo -e "${YELLOW}⚠️  Warning: No #include statements found${NC}"
    ((STYLE_ISSUES++))
fi

if ! grep -q "int main" student_solution.c; then
    echo -e "${RED}❌ Error: No main function found${NC}"
    ((STYLE_ISSUES += 2))
fi

if ! grep -q "return" student_solution.c; then
    echo -e "${YELLOW}⚠️  Warning: No return statement found${NC}"
    ((STYLE_ISSUES++))
fi

# Check for dangerous functions
if grep -q "gets\|strcpy\|strcat\|sprintf" student_solution.c; then
    echo -e "${YELLOW}⚠️  Warning: Potentially unsafe functions detected${NC}"
    ((STYLE_ISSUES++))
fi

# Calculate style score
if [[ $STYLE_ISSUES -eq 0 ]]; then
    STYLE_SCORE=$STYLE_POINTS
    echo -e "${GREEN}✅ Code quality check passed${NC}"
elif [[ $STYLE_ISSUES -le 2 ]]; then
    STYLE_SCORE=$((STYLE_POINTS * 3 / 4))
    echo -e "${YELLOW}⚠️  Minor code quality issues found${NC}"
else
    STYLE_SCORE=$((STYLE_POINTS / 2))
    echo -e "${YELLOW}⚠️  Multiple code quality issues found${NC}"
fi

log_result "Code quality score: $STYLE_SCORE/$STYLE_POINTS (issues: $STYLE_ISSUES)"

# Step 3: Compilation
echo -e "${BLUE}=== Step 3: Compilation ===${NC}"

# Clean any previous builds
if make clean >/dev/null 2>&1; then
    echo "Cleaned previous build files"
fi

# Try strict compilation first
echo "Attempting compilation with strict settings..."
if make > compilation_normal.log 2>&1; then
    echo -e "${YELLOW}⚠️  Compilation successful with warnings${NC}"
    COMPILATION_SCORE=$((COMPILATION_POINTS * 4 / 5))
    COMPILER_MODE="normal"
    echo "Compilation warnings:"
    cat compilation_normal.log | head -n 10
else
    echo -e "${RED}❌ Compilation failed${NC}"
    echo "Compilation errors:"
    cat compilation_normal.log
    COMPILATION_SCORE=0
    log_result "COMPILATION FAILED"
    log_result "Errors:"
    cat compilation_normal.log >> test_results/detailed_log.txt
    
    # Create summary and exit
    {
        echo "FINAL_SCORE: 0"
        echo "TOTAL_POSSIBLE: $TOTAL_POINTS"
        echo "COMPILATION: FAILED"
        echo "REASON: Compilation errors"
    } > test_results/summary.txt
    exit 1
fi

# Verify executable was created
if [[ ! -f "program" ]]; then
    echo -e "${RED}❌ ERROR: Executable 'program' not created${NC}"
    log_result "ERROR: No executable produced"
    exit 1
fi

log_result "Compilation: $COMPILATION_SCORE/$COMPILATION_POINTS ($COMPILER_MODE mode)"

# Step 4: Testing
echo -e "${BLUE}=== Step 4: Running Test Cases ===${NC}"

# Check if tests directory exists
if [[ ! -d "tests" ]]; then
    echo -e "${RED}❌ ERROR: tests/ directory not found${NC}"
    log_result "ERROR: No tests directory"
    exit 1
fi

# Find all test cases
TEST_INPUTS=(tests/testcases/input*.txt)
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
    expected_file="tests/expected/output${test_num}.txt"
    
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
    student_output="test_results/student_output_${test_num}.txt"
    
    if timeout $TIMEOUT_SECONDS ./program < "$input_file" > "$student_output" 2>/dev/null; then
        # Compare outputs (ignore trailing whitespace)
        if diff -w -B "$expected_file" "$student_output" > "test_results/diff_${test_num}.txt" 2>&1; then
            echo -e "${GREEN}✅ Test $test_num: PASSED${NC}"
            log_result "Test $test_num: PASSED"
            ((PASSED_TESTS++))
        else
            echo -e "${RED}❌ Test $test_num: FAILED (incorrect output)${NC}"
            echo "Your output:"
            cat "$student_output" | sed 's/^/  /'
            echo "Difference:"
            head -n 5 "test_results/diff_${test_num}.txt" | sed 's/^/  /'
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

# Check for late penalty
LATE_PENALTY=${LATE_PENALTY:-0}
SUBTOTAL=$((COMPILATION_SCORE + TEST_SCORE + STYLE_SCORE))
FINAL_SCORE=$((SUBTOTAL - LATE_PENALTY))

if [[ $FINAL_SCORE -lt 0 ]]; then
    FINAL_SCORE=0
fi

# Display results
echo "┌─────────────────────────────────────┐"
echo "│           GRADE BREAKDOWN           │"
echo "├─────────────────────────────────────┤"
printf "│ Compilation:      %3d/%3d points   │\n" $COMPILATION_SCORE $COMPILATION_POINTS
printf "│ Test Cases:       %3d/%3d points   │\n" $TEST_SCORE $TEST_POINTS
printf "│ Code Quality:     %3d/%3d points   │\n" $STYLE_SCORE $STYLE_POINTS
echo "├─────────────────────────────────────┤"
printf "│ Subtotal:         %3d/%3d points   │\n" $SUBTOTAL $TOTAL_POINTS

if [[ $LATE_PENALTY -gt 0 ]]; then
    printf "│ Late Penalty:     -%2d points       │\n" $LATE_PENALTY
fi

echo "├─────────────────────────────────────┤"
printf "│ FINAL SCORE:      %3d/%3d points   │\n" $FINAL_SCORE $TOTAL_POINTS
printf "│ PERCENTAGE:           %3d%%          │\n" $((FINAL_SCORE * 100 / TOTAL_POINTS))
echo "└─────────────────────────────────────┘"

# Determine letter grade (optional)
PERCENTAGE=$((FINAL_SCORE * 100 / TOTAL_POINTS))
if [[ $PERCENTAGE -ge 90 ]]; then
    LETTER_GRADE="A"
elif [[ $PERCENTAGE -ge 80 ]]; then
    LETTER_GRADE="B"
elif [[ $PERCENTAGE -ge 70 ]]; then
    LETTER_GRADE="C"
elif [[ $PERCENTAGE -ge 60 ]]; then
    LETTER_GRADE="D"
else
    LETTER_GRADE="F"
fi

echo -e "${GREEN}Letter Grade: $LETTER_GRADE${NC}"

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
} > test_results/summary.txt

log_result "=== FINAL SUMMARY ==="
log_result "Score: $FINAL_SCORE/$TOTAL_POINTS ($PERCENTAGE%)"
log_result "Grade: $LETTER_GRADE"
log_result "Tests passed: $PASSED_TESTS/$TOTAL_TESTS"

echo
echo "Detailed results saved to test_results/ directory"
echo "Summary available in test_results/summary.txt"

# Exit with appropriate code for GitHub Actions
if [[ $FINAL_SCORE -ge $((TOTAL_POINTS * 6 / 10)) ]]; then
    echo -e "${GREEN}🎉 Congratulations! Assignment completed successfully.${NC}"
    exit 0
else
    echo -e "${YELLOW}📚 Assignment needs improvement. Keep working on it!${NC}"
    exit 1
fi
