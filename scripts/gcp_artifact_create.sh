#!/bin/bash

# Colors for better visualization
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
LOCATION="us-west1"
PROJECT="orkestaten"

# Banner
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}GCP Artifact Registry - Repository Creator${NC}           ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Display current configuration
echo -e "${BLUE}📋 Configuration:${NC}"
echo -e "   ${CYAN}Project:${NC}  ${PROJECT}"
echo -e "   ${CYAN}Location:${NC} ${LOCATION}"
echo ""

# Get repository names from user
echo -e "${YELLOW}📝 Enter repository names:${NC}"
echo -e "${YELLOW}   • Separate multiple names with commas${NC}"
echo -e "${YELLOW}   • Example: api-service,frontend-service,backend-service${NC}"
echo ""

while true; do
  read -p "$(echo -e ${MAGENTA}Repository names${NC}: )" repo_input

  # Check if input is empty
  if [ -z "$repo_input" ]; then
    echo -e "${RED}   ❌ You must enter at least one repository name!${NC}"
    continue
  fi

  # Split by comma and trim whitespace
  IFS=',' read -ra REPOS <<< "$repo_input"

  # Trim whitespace and validate each repository name
  VALID_REPOS=()
  INVALID_REPOS=()

  for repo in "${REPOS[@]}"; do
    # Trim leading/trailing whitespace
    repo=$(echo "$repo" | xargs)

    # Skip empty entries
    if [ -z "$repo" ]; then
      continue
    fi

    # Validate repository name (lowercase, numbers, hyphens only)
    if [[ "$repo" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]] || [[ "$repo" =~ ^[a-z0-9]$ ]]; then
      VALID_REPOS+=("$repo")
    else
      INVALID_REPOS+=("$repo")
    fi
  done

  # Show validation results
  if [ ${#INVALID_REPOS[@]} -gt 0 ]; then
    echo -e "${RED}   ❌ Invalid repository names:${NC}"
    for invalid in "${INVALID_REPOS[@]}"; do
      echo -e "      ${RED}•${NC} ${invalid}"
    done
    echo -e "${YELLOW}   Repository names must:${NC}"
    echo -e "      ${YELLOW}• Start and end with lowercase letter or number${NC}"
    echo -e "      ${YELLOW}• Contain only lowercase letters, numbers, and hyphens${NC}"
    echo ""
    continue
  fi

  if [ ${#VALID_REPOS[@]} -eq 0 ]; then
    echo -e "${RED}   ❌ No valid repository names found!${NC}"
    continue
  fi

  # Success - break the loop
  REPOS=("${VALID_REPOS[@]}")
  break
done

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}📦 Repositories to create (${#REPOS[@]} total):${NC}"
for i in "${!REPOS[@]}"; do
  echo -e "   ${CYAN}$((i+1)).${NC} ${REPOS[$i]}"
done
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""

# Confirm before proceeding
read -p "$(echo -e ${YELLOW}Continue with creation? ${BOLD}[y/N]${NC}: )" confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo -e "${RED}❌ Operation cancelled${NC}"
  exit 0
fi

echo ""
echo -e "${BLUE}⚙️  Creating cleanup policy configuration...${NC}"

# Create cleanup policy file
cat > /tmp/cleanup-policy.json <<EOF
[
  {
    "name": "delete-old-images",
    "action": {"type": "Delete"},
    "condition": {
      "tagState": "any",
      "olderThan": "86400s"
    }
  },
  {
    "name": "keep-recent-versions",
    "action": {"type": "Keep"},
    "mostRecentVersions": {
      "keepCount": 2
    }
  }
]
EOF

echo -e "${GREEN}   ✓ Policy created${NC}"
echo ""
echo -e "${BLUE}📦 Repository Configuration:${NC}"
echo -e "   ${CYAN}•${NC} Format: ${BOLD}Docker${NC}"
echo -e "   ${CYAN}•${NC} Vulnerability Scanning: ${BOLD}Disabled${NC}"
echo ""
echo -e "${BLUE}📦 Cleanup Policy Details:${NC}"
echo -e "   ${CYAN}•${NC} Delete images older than: ${BOLD}1 day${NC}"
echo -e "   ${CYAN}•${NC} Keep most recent versions: ${BOLD}2${NC}"
echo -e "   ${CYAN}•${NC} Dry-run mode: ${BOLD}ENABLED${NC} (safe mode)"
echo ""

# Progress tracking
SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_REPOS=()

# Create each repository
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}🚀 Starting repository creation...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""

for i in "${!REPOS[@]}"; do
  REPO="${REPOS[$i]}"
  CURRENT=$((i+1))
  TOTAL=${#REPOS[@]}

  echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
  echo -e "${CYAN}│${NC} ${BOLD}[$CURRENT/$TOTAL] Processing: $REPO${NC}"
  echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"

  # Step 1: Create repository
  echo -e "${BLUE}   [1/2] Creating repository...${NC}"

  CREATE_OUTPUT=$(gcloud artifacts repositories create $REPO \
    --repository-format=docker \
    --location=$LOCATION \
    --project=$PROJECT \
    --description="Docker repository for $REPO" \
    --disable-vulnerability-scanning 2>&1)

  CREATE_EXIT_CODE=$?

  if [ $CREATE_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}   ✓ Repository created successfully${NC}"

    # Step 2: Set cleanup policies
    echo -e "${BLUE}   [2/2] Applying cleanup policies...${NC}"

    POLICY_OUTPUT=$(gcloud artifacts repositories set-cleanup-policies $REPO \
      --location=$LOCATION \
      --project=$PROJECT \
      --policy=/tmp/cleanup-policy.json \
      --dry-run 2>&1)

    POLICY_EXIT_CODE=$?

    if [ $POLICY_EXIT_CODE -eq 0 ]; then
      echo -e "${GREEN}   ✓ Cleanup policies applied${NC}"
      echo -e "${GREEN}   ✓ Registry URI: ${BOLD}${LOCATION}-docker.pkg.dev/${PROJECT}/${REPO}${NC}"
      SUCCESS_COUNT=$((SUCCESS_COUNT+1))
    else
      echo -e "${RED}   ❌ Failed to apply cleanup policies${NC}"
      echo -e "${YELLOW}   ⚠️  Repository created but policies failed${NC}"
      echo -e "${RED}   Error details:${NC}"
      echo "$POLICY_OUTPUT" | while IFS= read -r line; do
        echo -e "${RED}   $line${NC}"
      done
      FAILED_COUNT=$((FAILED_COUNT+1))
      FAILED_REPOS+=("$REPO (policy failed)")
    fi
  else
    echo -e "${RED}   ❌ Failed to create repository${NC}"
    if [[ "$CREATE_OUTPUT" == *"already exists"* ]]; then
      echo -e "${YELLOW}   ⚠️  Repository already exists${NC}"
    else
      echo -e "${RED}   Error details:${NC}"
      echo "$CREATE_OUTPUT" | while IFS= read -r line; do
        echo -e "${RED}   $line${NC}"
      done
    fi
    FAILED_COUNT=$((FAILED_COUNT+1))
    FAILED_REPOS+=("$REPO")
  fi

  echo ""
done

# Cleanup temp file
rm -f /tmp/cleanup-policy.json

# Final summary
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}📊 FINAL SUMMARY${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Successfully created: ${BOLD}${SUCCESS_COUNT}${NC} repositories"
echo -e "${RED}❌ Failed: ${BOLD}${FAILED_COUNT}${NC} repositories"
echo -e "${CYAN}📦 Total processed: ${BOLD}${TOTAL}${NC} repositories"
echo ""

if [ $SUCCESS_COUNT -gt 0 ]; then
  echo -e "${GREEN}${BOLD}✓ Successfully created repositories:${NC}"
  for REPO in "${REPOS[@]}"; do
    # Check if repo is in failed list
    REPO_FAILED=0
    for FAILED_REPO in "${FAILED_REPOS[@]}"; do
      if [[ "$FAILED_REPO" == "$REPO"* ]]; then
        REPO_FAILED=1
        break
      fi
    done

    if [ $REPO_FAILED -eq 0 ]; then
      echo -e "   ${GREEN}•${NC} ${REPO}"
      echo -e "     ${CYAN}URI:${NC} ${LOCATION}-docker.pkg.dev/${PROJECT}/${REPO}"
    fi
  done
  echo ""
fi

if [ $FAILED_COUNT -gt 0 ]; then
  echo -e "${RED}${BOLD}✗ Failed repositories:${NC}"
  for FAILED_REPO in "${FAILED_REPOS[@]}"; do
    echo -e "   ${RED}•${NC} ${FAILED_REPO}"
  done
  echo ""
fi

echo -e "${BLUE}📝 Next steps:${NC}"
echo -e "   ${CYAN}1.${NC} Configure Docker authentication:"
echo -e "      ${BOLD}gcloud auth configure-docker ${LOCATION}-docker.pkg.dev${NC}"
echo -e "   ${CYAN}2.${NC} Push images to your repository:"
echo -e "      ${BOLD}docker tag IMAGE ${LOCATION}-docker.pkg.dev/${PROJECT}/REPO:TAG${NC}"
echo -e "      ${BOLD}docker push ${LOCATION}-docker.pkg.dev/${PROJECT}/REPO:TAG${NC}"
echo -e "   ${CYAN}3.${NC} View repositories:"
echo -e "      ${BOLD}gcloud artifacts repositories list --location=${LOCATION}${NC}"
echo ""

if [ $SUCCESS_COUNT -eq $TOTAL ]; then
  echo -e "${GREEN}${BOLD}🎉 All repositories created successfully!${NC}"
  exit 0
else
  echo -e "${YELLOW}${BOLD}⚠️  Some repositories failed. Please check errors above.${NC}"
  exit 1
fi
