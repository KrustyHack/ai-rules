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

# Default behavior flags
FORCE_UPDATE=false
UPDATE_MODE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE_UPDATE=true
            shift
            ;;
        -u|--update)
            UPDATE_MODE=true
            FORCE_UPDATE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -f, --force    Force update without confirmation"
            echo "  -u, --update   Update mode - same as --force but clearer intent"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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
if [[ "$UPDATE_MODE" == true ]]; then
    echo -e "   • Mode: ${YELLOW}Update (existing files will be replaced)${NC}"
elif [[ "$FORCE_UPDATE" == true ]]; then
    echo -e "   • Mode: ${YELLOW}Force (no confirmation for conflicts)${NC}"
else
    echo -e "   • Mode: ${YELLOW}Interactive (will ask before replacing existing files)${NC}"
fi
echo ""

# Ask for confirmation unless force mode is enabled
if [[ "$FORCE_UPDATE" == false ]]; then
    echo -e "${YELLOW}❓ Do you want to proceed with installing AI rules for Cursor? (y/N)${NC}"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation cancelled by user.${NC}"
        exit 0
    fi
else
    if [[ "$UPDATE_MODE" == true ]]; then
        echo -e "${GREEN}✅ Running in update mode - proceeding automatically${NC}"
    else
        echo -e "${GREEN}✅ Running in force mode - proceeding automatically${NC}"
    fi
    echo ""
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

# Count items in rules directory
ITEMS_COUNT=$(find "$RULES_PATH" -type f | wc -l)
echo -e "${BLUE}📁 Found $ITEMS_COUNT files in rules directory${NC}"

# Display list of directories/files to be installed
echo -e "${BLUE}   Content to install:${NC}"
while IFS= read -r -d '' item; do
    if [[ -e "$item" ]]; then
        basename_item=$(basename "$item")
        if [[ -d "$item" ]]; then
            file_count=$(find "$item" -type f | wc -l)
            echo -e "   • ${YELLOW}$basename_item/${NC} (${file_count} files)"
        else
            echo -e "   • ${YELLOW}$basename_item${NC}"
        fi
    fi
done < <(find "$RULES_PATH" -maxdepth 1 -mindepth 1 -print0)
echo ""

# Copy rules content to original directory
echo -e "${BLUE}📋 Installing files...${NC}"
COPIED_ITEMS=0
CONFLICTS=0

# Check if the source contains a .cursor directory structure
if [[ -d "$RULES_PATH/.cursor/rules/ack" ]]; then
    # Install specific ack directory only
    echo -e "${BLUE}   Installing Cursor rules (ack directory only)...${NC}"
    
    # Create .cursor/rules directory if it doesn't exist
    mkdir -p "$ORIGINAL_DIR/.cursor/rules"
    
    # Handle the ack directory specifically
    ACK_SOURCE="$RULES_PATH/.cursor/rules/ack"
    ACK_TARGET="$ORIGINAL_DIR/.cursor/rules/ack"
    
    # Track if this is an update
    IS_UPDATE=false
    
    if [[ -e "$ACK_TARGET" ]]; then
        IS_UPDATE=true
        if [[ "$FORCE_UPDATE" == true ]]; then
            echo -e "${YELLOW}🔄 .cursor/rules/ack already exists - updating...${NC}"
            # Remove existing ack directory
            rm -rf "$ACK_TARGET"
        else
            echo -e "${YELLOW}⚠️  .cursor/rules/ack already exists. Replace? (y/N)${NC}"
            read -r replace
            if [[ ! "$replace" =~ ^[Yy]$ ]]; then
                echo -e "   ⏭️  .cursor/rules/ack skipped."
                ((CONFLICTS++))
            else
                # Remove existing ack directory
                rm -rf "$ACK_TARGET"
            fi
        fi
    fi
    
    # Copy the ack directory if not skipped
    if [[ ! -e "$ACK_TARGET" ]]; then
        if cp -r "$ACK_SOURCE" "$ACK_TARGET" 2>/dev/null; then
            if [[ "$IS_UPDATE" == true ]]; then
                echo -e "${GREEN}   ✅ .cursor/rules/ack updated${NC}"
            else
                echo -e "${GREEN}   ✅ .cursor/rules/ack installed${NC}"
            fi
            ((COPIED_ITEMS++))
        else
            echo -e "${RED}   ❌ Failed to install .cursor/rules/ack${NC}"
        fi
    fi
else
    # Fallback to old behavior for other file structures
    while IFS= read -r -d '' item; do
        if [[ -e "$item" ]]; then
            item_name=$(basename "$item")
            target_path="$ORIGINAL_DIR/$item_name"
            
            # Track if this is an update
            IS_UPDATE=false
            
            # Check if item already exists
            if [[ -e "$target_path" ]]; then
                IS_UPDATE=true
                if [[ "$FORCE_UPDATE" == true ]]; then
                    echo -e "${YELLOW}🔄 $item_name already exists - updating...${NC}"
                    # Remove existing item before copying
                    rm -rf "$target_path"
                else
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
            fi
            
            # Copy the item (file or directory)
            if cp -r "$item" "$target_path" 2>/dev/null; then
                if [[ "$IS_UPDATE" == true ]]; then
                    echo -e "${GREEN}   ✅ $item_name updated${NC}"
                else
                    echo -e "${GREEN}   ✅ $item_name installed${NC}"
                fi
                ((COPIED_ITEMS++))
            else
                echo -e "${RED}   ❌ Failed to install $item_name${NC}"
            fi
        fi
    done < <(find "$RULES_PATH" -maxdepth 1 -mindepth 1 -print0)
fi

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
if [[ -d "$ORIGINAL_DIR/.cursor/rules/ack" ]]; then
    rule_files_count=$(find "$ORIGINAL_DIR/.cursor/rules/ack" -name "*.mdc" | wc -l)
    echo -e "${GREEN}✅ Verification: Found $rule_files_count .mdc files in .cursor/rules/ack directory${NC}"
elif [[ -d "$ORIGINAL_DIR/.cursor" ]]; then
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