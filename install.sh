#!/bin/bash

# Colors for display
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/KrustyHack/ai-rules.git"
REPO_NAME="ai-rules"
RULES_SOURCE_DIR="rules"

# Store the original directory at the very beginning
ORIGINAL_DIR="$(pwd)"

echo -e "${BLUE}=== AI Rules Installer for Cursor ===${NC}"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if we're in a project directory
if [[ ! -d ".git" && ! -f "package.json" && ! -f "requirements.txt" && ! -f "Cargo.toml" && ! -f "go.mod" ]]; then
    echo -e "${YELLOW}⚠️  Warning: You don't seem to be in a project directory.${NC}"
    echo -e "   Do you want to continue anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation cancelled.${NC}"
        exit 0
    fi
fi

# Display installation information
echo -e "${BLUE}📋 Installation information:${NC}"
echo -e "   • Source repo: ${YELLOW}$REPO_URL${NC}"
echo -e "   • Destination: ${YELLOW}$ORIGINAL_DIR${NC}"
echo -e "   • Content: ${YELLOW}Rules and configuration folders${NC}"
echo ""

# Ask for confirmation
echo -e "${YELLOW}❓ Do you want to proceed with installing AI rules for Cursor? (y/N)${NC}"
read -r confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Installation cancelled by user.${NC}"
    exit 0
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "${BLUE}📥 Cloning repository...${NC}"
cd "$TEMP_DIR" || exit 1

if ! git clone "$REPO_URL" "$REPO_NAME" 2>/dev/null; then
    echo -e "${RED}❌ Error cloning repository.${NC}"
    echo -e "   Please check your internet connection and repository access."
    exit 1
fi

# Set the rules source path
RULES_PATH="${TEMP_DIR}/${REPO_NAME}/${RULES_SOURCE_DIR}"

# Check if rules directory exists
if [[ ! -d "$RULES_PATH" ]]; then
    echo -e "${RED}❌ Rules directory not found in the repository.${NC}"
    echo -e "   Expected path: $RULES_PATH"
    exit 1
fi

echo -e "${GREEN}✅ Repository cloned successfully.${NC}"

# Debug: Show the actual content of the rules directory
echo -e "${BLUE}🔍 Debug: Rules directory content:${NC}"
ls -la "$RULES_PATH"
echo ""

# Count items in rules directory
ITEMS_COUNT=$(find "$RULES_PATH" -type f | wc -l)
echo -e "${BLUE}📁 Found $ITEMS_COUNT files in rules directory${NC}"

# Display list of directories/files to be installed
echo -e "${BLUE}   Content to install:${NC}"
for item in "$RULES_PATH"/*; do
    echo -e "${BLUE}🔍 Debug: Checking item: $item${NC}"
    if [[ -e "$item" ]]; then
        basename_item=$(basename "$item")
        if [[ -d "$item" ]]; then
            file_count=$(find "$item" -type f | wc -l)
            echo -e "   • ${YELLOW}$basename_item/${NC} (${file_count} files)"
        else
            echo -e "   • ${YELLOW}$basename_item${NC}"
        fi
    else
        echo -e "${RED}🔍 Debug: Item does not exist: $item${NC}"
    fi
done
echo ""

# Copy rules content to original directory
echo -e "${BLUE}📋 Installing files...${NC}"
COPIED_ITEMS=0
CONFLICTS=0

for item in "$RULES_PATH"/*; do
    echo -e "${BLUE}🔍 Debug: Processing item for copy: $item${NC}"
    if [[ -e "$item" ]]; then
        item_name=$(basename "$item")
        target_path="$ORIGINAL_DIR/$item_name"
        
        echo -e "${BLUE}🔍 Debug: Will copy $item to $target_path${NC}"
        
        # Check if item already exists
        if [[ -e "$target_path" ]]; then
            echo -e "${YELLOW}⚠️  $item_name already exists. Replace? (y/N)${NC}"
            read -r replace
            if [[ ! "$replace" =~ ^[Yy]$ ]]; then
                echo -e "   ⏭️  $item_name skipped."
                ((CONFLICTS++))
                continue
            fi
            # Remove existing item before copying
            rm -rf "$target_path"
        fi
        
        # Copy the item (file or directory)
        if cp -r "$item" "$target_path" 2>/dev/null; then
            echo -e "${GREEN}   ✅ $item_name installed${NC}"
            ((COPIED_ITEMS++))
        else
            echo -e "${RED}   ❌ Failed to install $item_name${NC}"
        fi
    else
        echo -e "${RED}🔍 Debug: Item does not exist for copy: $item${NC}"
    fi
done

echo ""
echo -e "${GREEN}🎉 Installation completed!${NC}"
echo -e "${BLUE}📊 Summary:${NC}"
echo -e "   • Items installed: ${GREEN}$COPIED_ITEMS${NC}"
if [[ $CONFLICTS -gt 0 ]]; then
    echo -e "   • Items skipped: ${YELLOW}$CONFLICTS${NC}"
fi
echo -e "   • Installation directory: ${YELLOW}$ORIGINAL_DIR${NC}"
echo ""

# Verify installation
if [[ -d "$ORIGINAL_DIR/.cursor" ]]; then
    rule_files_count=$(find "$ORIGINAL_DIR/.cursor" -name "*.mdc" | wc -l)
    echo -e "${GREEN}✅ Verification: Found $rule_files_count .mdc files in .cursor directory${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: .cursor directory not found in installation path${NC}"
fi
echo ""

echo -e "${BLUE}💡 To use these rules in Cursor:${NC}"
echo -e "   1. Restart Cursor"
echo -e "   2. Rules will be automatically loaded from the installed directories"
echo -e "   3. You can verify in Cursor settings > Rules"
echo ""
echo -e "${GREEN}✨ Enjoy your new AI rules!${NC}" 