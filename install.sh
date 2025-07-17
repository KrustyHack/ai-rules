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
CURSOR_RULES_DIR=".cursor/rules"

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
echo -e "   • Destination: ${YELLOW}$(pwd)/$CURSOR_RULES_DIR${NC}"
echo -e "   • Files to install: ${YELLOW}All .mdc files from the repo${NC}"
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

cd "$REPO_NAME" || exit 1

# Count .mdc files
MDC_FILES=(*.mdc)
if [[ ! -e "${MDC_FILES[0]}" ]]; then
    echo -e "${RED}❌ No .mdc files found in the repository.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Repository cloned successfully.${NC}"
echo -e "${BLUE}📁 Found .mdc files: ${#MDC_FILES[@]}${NC}"

# Display list of files to be installed
echo -e "${BLUE}   Files to install:${NC}"
for file in "${MDC_FILES[@]}"; do
    echo -e "   • ${YELLOW}$file${NC}"
done
echo ""

# Return to original directory
cd - > /dev/null || exit 1

# Create .cursor/rules directory if it doesn't exist
echo -e "${BLUE}📂 Creating $CURSOR_RULES_DIR directory...${NC}"
mkdir -p "$CURSOR_RULES_DIR"

# Copy .mdc files
echo -e "${BLUE}📋 Installing files...${NC}"
INSTALLED_COUNT=0

for file in "${TEMP_DIR}/${REPO_NAME}"/*.mdc; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        target_path="$CURSOR_RULES_DIR/$filename"
        
        # Check if file already exists
        if [[ -f "$target_path" ]]; then
            echo -e "${YELLOW}⚠️  File $filename already exists. Replace? (y/N)${NC}"
            read -r replace
            if [[ ! "$replace" =~ ^[Yy]$ ]]; then
                echo -e "   ⏭️  File $filename skipped."
                continue
            fi
        fi
        
        cp "$file" "$target_path"
        echo -e "${GREEN}   ✅ $filename installed${NC}"
        ((INSTALLED_COUNT++))
    fi
done

echo ""
echo -e "${GREEN}🎉 Installation completed!${NC}"
echo -e "${BLUE}📊 Summary:${NC}"
echo -e "   • Files installed: ${GREEN}$INSTALLED_COUNT${NC}"
echo -e "   • Destination folder: ${YELLOW}$(pwd)/$CURSOR_RULES_DIR${NC}"
echo ""
echo -e "${BLUE}💡 To use these rules in Cursor:${NC}"
echo -e "   1. Restart Cursor"
echo -e "   2. Rules will be automatically loaded from $CURSOR_RULES_DIR"
echo -e "   3. You can verify in Cursor settings > Rules"
echo ""
echo -e "${GREEN}✨ Enjoy your new AI rules!${NC}" 