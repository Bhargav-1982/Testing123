# Student Instructions: Assignment Submission via GitHub

## Quick Start Guide

### Step 1: Accept the Assignment

1. Click the assignment link provided by your professor
2. Sign in to GitHub (create account if needed)
3. Click "Accept this assignment"
4. Wait for your repository to be created

### Step 2: Edit Your Solution

1. Click on the `student_solution.c` file in your repository
2. Click the pencil icon (✏️) to edit
3. Write your C code to solve the assignment
4. Scroll down to "Commit changes"
5. Add a message like "Submit assignment attempt 1"
6. Click "Commit changes"

### Step 3: Check Your Grade

1. Click the "Actions" tab in your repository
2. Wait 2-3 minutes for the autograder to finish
3. Click on the latest workflow run to see detailed results
4. Your grade will be displayed at the bottom

### Step 4: Improve and Resubmit (Optional)

1. If your grade isn't perfect, go back to step 2
2. Edit your code to fix any issues
3. Commit again with a new message like "Fix test case 2"
4. Check your new grade in Actions tab

## Understanding Your Results

### ✅ What Success Looks Like:

```
=== FINAL RESULTS ===
Compilation:      15/15 points
Test Cases:       80/80 points  
Code Quality:      5/5 points
FINAL SCORE:     100/100 points
PERCENTAGE:           100%
Letter Grade: A
```

### ❌ What Failure Looks Like:

```
=== FINAL RESULTS ===
Compilation:      15/15 points
Test Cases:       40/80 points  (2/4 tests passed)
Code Quality:      5/5 points
FINAL SCORE:      60/100 points
PERCENTAGE:            60%
Letter Grade: D
```

### 🔍 How to Debug Issues:

**Compilation Failed:**

- Check for missing semicolons
- Make sure you have `#include <stdio.h>`
- Verify all brackets `{}` are matched

**Test Case Failed:**

- Check the expected output format exactly
- Make sure you're reading input correctly with `scanf`
- Verify your calculations are correct

**Timeout/Crash:**

- Avoid infinite loops
- Initialize all variables
- Check for division by zero

## Sample Working Solution

```c
#include <stdio.h>

int main() {
    int a, b;
    
    // Read two integers
    scanf("%d %d", &a, &b);
    
    // Calculate and output results
    printf("%d\n", a + b);      // sum
    printf("%d\n", a - b);      // difference  
    printf("%d\n", a * b);      // product
    
    return 0;
}
```

## Submission Tips

### ✅ DO:

- Start early and submit multiple times
- Test with the provided examples
- Read error messages carefully
- Ask for help during office hours

### ❌ DON'T:

- Wait until the last minute
- Share your code with other students
- Copy solutions from the internet
- Submit without testing

## Getting Help

1. **Check the assignment README** for examples and requirements
2. **Look at the test results** in the Actions tab for specific errors
3. **Ask questions** during office hours or on the course forum
4. **Test locally** if you have a C compiler installed

## Academic Integrity Reminder

- Write your own code
- Don't share your repository with other students
- Don't copy from online sources
- Collaboration on concepts is OK, but code must be your own

**Good luck with your assignment!**
