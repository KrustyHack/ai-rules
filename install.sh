#!/bin/bash

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="git@github.com:KrustyHack/ai-rules.git"
REPO_NAME="ai-rules"
CURSOR_RULES_DIR=".cursor/rules"

echo -e "${BLUE}=== AI Rules Installer pour Cursor ===${NC}"
echo ""

# Vérifier si git est installé
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git n'est pas installé. Veuillez l'installer d'abord.${NC}"
    exit 1
fi

# Vérifier si nous sommes dans un projet (présence d'un dossier .git ou autre)
if [[ ! -d ".git" && ! -f "package.json" && ! -f "requirements.txt" && ! -f "Cargo.toml" && ! -f "go.mod" ]]; then
    echo -e "${YELLOW}⚠️  Attention: Vous ne semblez pas être dans un dossier de projet.${NC}"
    echo -e "   Voulez-vous continuer quand même ? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation annulée.${NC}"
        exit 0
    fi
fi

# Vérifier l'accès SSH à GitHub
echo -e "${BLUE}🔑 Vérification de l'accès SSH à GitHub...${NC}"
if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${RED}❌ Impossible d'accéder à GitHub via SSH.${NC}"
    echo -e "   Assurez-vous que:"
    echo -e "   1. Votre clé SSH est configurée: ${YELLOW}ssh-keygen -t ed25519 -C 'your_email@example.com'${NC}"
    echo -e "   2. Votre clé publique est ajoutée à GitHub"
    echo -e "   3. Testez avec: ${YELLOW}ssh -T git@github.com${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Accès SSH à GitHub confirmé.${NC}"
echo ""

# Afficher les informations sur ce qui va être installé
echo -e "${BLUE}📋 Informations sur l'installation:${NC}"
echo -e "   • Repo source: ${YELLOW}$REPO_URL${NC}"
echo -e "   • Destination: ${YELLOW}$(pwd)/$CURSOR_RULES_DIR${NC}"
echo -e "   • Fichiers à installer: ${YELLOW}Tous les fichiers .mdc du repo${NC}"
echo ""

# Demander confirmation
echo -e "${YELLOW}❓ Voulez-vous procéder à l'installation des règles AI pour Cursor ? (y/N)${NC}"
read -r confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Installation annulée par l'utilisateur.${NC}"
    exit 0
fi

# Créer un dossier temporaire
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "${BLUE}📥 Clonage du repository...${NC}"
cd "$TEMP_DIR" || exit 1

if ! git clone "$REPO_URL" "$REPO_NAME" 2>/dev/null; then
    echo -e "${RED}❌ Erreur lors du clonage du repository.${NC}"
    echo -e "   Vérifiez vos permissions d'accès au repo privé."
    exit 1
fi

cd "$REPO_NAME" || exit 1

# Compter les fichiers .mdc
MDC_FILES=(*.mdc)
if [[ ! -e "${MDC_FILES[0]}" ]]; then
    echo -e "${RED}❌ Aucun fichier .mdc trouvé dans le repository.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Repository cloné avec succès.${NC}"
echo -e "${BLUE}📁 Fichiers .mdc trouvés: ${#MDC_FILES[@]}${NC}"

# Afficher la liste des fichiers qui seront installés
echo -e "${BLUE}   Fichiers à installer:${NC}"
for file in "${MDC_FILES[@]}"; do
    echo -e "   • ${YELLOW}$file${NC}"
done
echo ""

# Revenir au dossier original
cd - > /dev/null || exit 1

# Créer le dossier .cursor/rules s'il n'existe pas
echo -e "${BLUE}📂 Création du dossier $CURSOR_RULES_DIR...${NC}"
mkdir -p "$CURSOR_RULES_DIR"

# Copier les fichiers .mdc
echo -e "${BLUE}📋 Installation des fichiers...${NC}"
INSTALLED_COUNT=0

for file in "${TEMP_DIR}/${REPO_NAME}"/*.mdc; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        target_path="$CURSOR_RULES_DIR/$filename"
        
        # Vérifier si le fichier existe déjà
        if [[ -f "$target_path" ]]; then
            echo -e "${YELLOW}⚠️  Le fichier $filename existe déjà. Remplacer ? (y/N)${NC}"
            read -r replace
            if [[ ! "$replace" =~ ^[Yy]$ ]]; then
                echo -e "   ⏭️  Fichier $filename ignoré."
                continue
            fi
        fi
        
        cp "$file" "$target_path"
        echo -e "${GREEN}   ✅ $filename installé${NC}"
        ((INSTALLED_COUNT++))
    fi
done

echo ""
echo -e "${GREEN}🎉 Installation terminée !${NC}"
echo -e "${BLUE}📊 Résumé:${NC}"
echo -e "   • Fichiers installés: ${GREEN}$INSTALLED_COUNT${NC}"
echo -e "   • Dossier de destination: ${YELLOW}$(pwd)/$CURSOR_RULES_DIR${NC}"
echo ""
echo -e "${BLUE}💡 Pour utiliser ces règles dans Cursor:${NC}"
echo -e "   1. Redémarrez Cursor"
echo -e "   2. Les règles seront automatiquement chargées depuis $CURSOR_RULES_DIR"
echo -e "   3. Vous pouvez vérifier dans les paramètres de Cursor > Rules"
echo ""
echo -e "${GREEN}✨ Profitez de vos nouvelles règles AI !${NC}" 