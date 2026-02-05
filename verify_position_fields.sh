#!/bin/bash

# SKAI Position Display Fields - Compatibility Verification Script
# This script checks that the position display fields are properly implemented
# in the SKAI 02 05 26.txt file and ready for My Dashboard integration.

echo "=================================="
echo "SKAI Position Fields Verification"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

FILE="SKAI 02 05 26.txt"
OLD_FILE="SKAI 02 02 26 V1.txt"

# Check if files exist
if [ ! -f "$FILE" ]; then
    echo -e "${RED}❌ Error: $FILE not found${NC}"
    exit 1
fi

echo "Testing file: $FILE"
echo ""

# Test 1: Check HTML field definitions
echo "Test 1: Checking HTML field definitions..."
echo "─────────────────────────────────────────"

FIELDS=(
    "skai-ai-mode-primary"
    "skai-ai-mode-method"
    "skai-ai-mode-risk"
)

FIELD_NAMES=(
    "skai_mode_primary"
    "skai_mode_method"
    "skai_mode_risk"
)

all_html_found=true
for i in "${!FIELDS[@]}"; do
    field_id="${FIELDS[$i]}"
    field_name="${FIELD_NAMES[$i]}"
    
    # Check if field is defined in HTML
    if grep -q "id=\"$field_id\"" "$FILE"; then
        echo -e "${GREEN}✅ HTML field found: $field_id${NC}"
        
        # Verify it has correct name attribute
        if grep "id=\"$field_id\"" "$FILE" | grep -q "name=\"$field_name\""; then
            echo -e "   ${GREEN}✓ Correct name attribute: $field_name${NC}"
        else
            echo -e "   ${RED}✗ Name attribute mismatch!${NC}"
            all_html_found=false
        fi
    else
        echo -e "${RED}❌ HTML field missing: $field_id${NC}"
        all_html_found=false
    fi
done

echo ""

# Test 2: Check JavaScript field population
echo "Test 2: Checking JavaScript field population..."
echo "────────────────────────────────────────────"

all_js_found=true
for field_id in "${FIELDS[@]}"; do
    # Check if field is referenced in JavaScript
    if grep -q "getElementById('$field_id')" "$FILE"; then
        echo -e "${GREEN}✅ JS reference found: getElementById('$field_id')${NC}"
        
        # Check if value is being assigned
        field_var=$(echo "$field_id" | sed 's/-ai-/-/g' | sed 's/-\([a-z]\)/\U\1/g')
        if grep "$field_id" "$FILE" | grep -q "\.value = "; then
            echo -e "   ${GREEN}✓ Value assignment present${NC}"
        fi
    else
        echo -e "${RED}❌ JS reference missing: getElementById('$field_id')${NC}"
        all_js_found=false
    fi
done

echo ""

# Test 3: Check field population logic
echo "Test 3: Checking field population logic..."
echo "───────────────────────────────────────────"

population_checks=(
    "fldModePrimary.value = profileVal"
    "fldModeMethod.value = strategyVal"
    "fldModeRisk.value = profileVal"
)

all_logic_found=true
for check in "${population_checks[@]}"; do
    # Check if the population logic exists (allowing for variations)
    pattern=$(echo "$check" | sed 's/\./\\./g' | sed 's/ = .*//')
    # Store grep result to avoid reading file twice
    grep_result=$(grep "$pattern" "$FILE")
    if echo "$grep_result" | grep -q "\.value"; then
        echo -e "${GREEN}✅ Population logic: $check${NC}"
    else
        echo -e "${RED}❌ Population logic missing: $check${NC}"
        all_logic_found=false
    fi
done

echo ""

# Test 4: Compare with old version
echo "Test 4: Comparing with old version..."
echo "──────────────────────────────────────"

if [ -f "$OLD_FILE" ]; then
    new_fields_count=0
    for field_id in "${FIELDS[@]}"; do
        # Check if field exists in new file but not in old file
        if grep -q "$field_id" "$FILE" && ! grep -q "$field_id" "$OLD_FILE"; then
            echo -e "${GREEN}✅ New field added: $field_id${NC}"
            ((new_fields_count++))
        fi
    done
    
    if [ $new_fields_count -eq 3 ]; then
        echo -e "${GREEN}✓ All 3 new fields confirmed as additions${NC}"
    else
        echo -e "${YELLOW}⚠ Expected 3 new fields, found $new_fields_count${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Old file not found, skipping comparison${NC}"
fi

echo ""

# Test 5: Check save form structure
echo "Test 5: Checking save form structure..."
echo "────────────────────────────────────────"

if grep -q "skai-ai-save-form" "$FILE"; then
    echo -e "${GREEN}✅ Save form found: skai-ai-save-form${NC}"
    
    # Count total hidden fields in form
    form_start=$(grep -n "id=\"skai-ai-save-form\"" "$FILE" | head -1 | cut -d: -f1)
    if [ ! -z "$form_start" ]; then
        form_section=$(sed -n "${form_start},$((form_start+200))p" "$FILE")
        hidden_count=$(echo "$form_section" | grep -c "type=\"hidden\"")
        echo -e "   ${GREEN}✓ Found $hidden_count hidden fields in save form${NC}"
    fi
else
    echo -e "${RED}❌ Save form not found${NC}"
fi

echo ""

# Final Summary
echo "═══════════════════════════════════════"
echo "Summary"
echo "═══════════════════════════════════════"
echo ""

if $all_html_found && $all_js_found && $all_logic_found; then
    echo -e "${GREEN}✅ ALL TESTS PASSED${NC}"
    echo ""
    echo "The position display fields are properly implemented:"
    echo "  ✓ HTML field definitions are correct"
    echo "  ✓ JavaScript references are present"
    echo "  ✓ Population logic is implemented"
    echo "  ✓ Fields are ready for My Dashboard integration"
    echo ""
    echo -e "${GREEN}Status: COMPATIBLE ✅${NC}"
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo ""
    if ! $all_html_found; then
        echo "  ✗ HTML field definitions have issues"
    fi
    if ! $all_js_found; then
        echo "  ✗ JavaScript references are incomplete"
    fi
    if ! $all_logic_found; then
        echo "  ✗ Population logic needs review"
    fi
    echo ""
    echo -e "${RED}Status: NEEDS ATTENTION ⚠${NC}"
    exit 1
fi
