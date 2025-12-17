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
PROJECT="Projectname"
REGION="us-west1"
CONNECTION="Connectionname"
GIT_ORG="gcp_org_name"
SERVICE_ACCOUNT="projects/orkestaten/serviceAccounts/codebuild@orkestaten.iam.gserviceaccount.com"

# Substitution variables
GIT_USER="git_user"
GIT_TOKEN="git_token"
SECRET_ID="1234567"

# Banner
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}GCP Cloud Build Trigger Creator${NC}                       ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Display current configuration
echo -e "${BLUE}📋 Configuration:${NC}"
echo -e "   ${CYAN}Project:${NC}          ${PROJECT}"
echo -e "   ${CYAN}Region:${NC}           ${REGION}"
echo -e "   ${CYAN}Connection:${NC}       ${CONNECTION}"
echo -e "   ${CYAN}Git Organization:${NC} ${GIT_ORG}"
echo -e "   ${CYAN}Service Account:${NC}  codebuild@orkestaten.iam.gserviceaccount.com"
echo ""

# Get repository/service names from user
echo -e "${YELLOW}📝 Enter service names (repository names):${NC}"
echo -e "${YELLOW}   • Separate multiple names with commas${NC}"
echo -e "${YELLOW}   • Repository format: ${GIT_ORG}-SERVICE_NAME${NC}"
echo -e "${YELLOW}   • Example: authorize-service,payment-service,order-service${NC}"
echo ""

while true; do
  read -p "$(echo -e ${MAGENTA}Service names${NC}: )" service_input

  # Check if input is empty
  if [ -z "$service_input" ]; then
    echo -e "${RED}   ❌ You must enter at least one service name!${NC}"
    continue
  fi

  # Split by comma and trim whitespace
  IFS=',' read -ra SERVICES <<< "$service_input"

  # Trim whitespace and validate each service name
  VALID_SERVICES=()
  INVALID_SERVICES=()

  for service in "${SERVICES[@]}"; do
    # Trim leading/trailing whitespace
    service=$(echo "$service" | xargs)

    # Skip empty entries
    if [ -z "$service" ]; then
      continue
    fi

    # Validate service name (lowercase, numbers, hyphens only)
    if [[ "$service" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]] || [[ "$service" =~ ^[a-z0-9]$ ]]; then
      VALID_SERVICES+=("$service")
    else
      INVALID_SERVICES+=("$service")
    fi
  done

  # Show validation results
  if [ ${#INVALID_SERVICES[@]} -gt 0 ]; then
    echo -e "${RED}   ❌ Invalid service names:${NC}"
    for invalid in "${INVALID_SERVICES[@]}"; do
      echo -e "      ${RED}•${NC} ${invalid}"
    done
    echo -e "${YELLOW}   Service names must:${NC}"
    echo -e "      ${YELLOW}• Start and end with lowercase letter or number${NC}"
    echo -e "      ${YELLOW}• Contain only lowercase letters, numbers, and hyphens${NC}"
    echo ""
    continue
  fi

  if [ ${#VALID_SERVICES[@]} -eq 0 ]; then
    echo -e "${RED}   ❌ No valid service names found!${NC}"
    continue
  fi

  # Success - break the loop
  SERVICES=("${VALID_SERVICES[@]}")
  break
done

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}🔨 Triggers to create (${#SERVICES[@]} total):${NC}"
for i in "${!SERVICES[@]}"; do
  SERVICE="${SERVICES[$i]}"
  REPO_NAME="${GIT_ORG}-${SERVICE}"
  echo -e "   ${CYAN}$((i+1)).${NC} ${BOLD}${SERVICE}${NC}"
  echo -e "      ${CYAN}Trigger Name:${NC} ${SERVICE}"
  echo -e "      ${CYAN}Repository:${NC}   ${REPO_NAME}"
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
echo -e "${BLUE}📦 Trigger Configuration:${NC}"
echo -e "   ${CYAN}•${NC} Build Config: ${BOLD}cloudbuild.yaml${NC}"
echo -e "   ${CYAN}•${NC} Trigger on: ${BOLD}Tag push (all tags)${NC}"
echo -e "   ${CYAN}•${NC} Build Logs: ${BOLD}Include with status${NC}"
echo ""

# Progress tracking
SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_TRIGGERS=()

# Create each trigger
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}🚀 Starting trigger creation...${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""

for i in "${!SERVICES[@]}"; do
  SERVICE="${SERVICES[$i]}"
  REPO_NAME="${GIT_ORG}-${SERVICE}"
  CURRENT=$((i+1))
  TOTAL=${#SERVICES[@]}

  echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
  echo -e "${CYAN}│${NC} ${BOLD}[$CURRENT/$TOTAL] Processing: ${SERVICE}${NC}"
  echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"

  echo -e "${BLUE}   Creating Cloud Build trigger...${NC}"
  echo -e "   ${CYAN}Repository:${NC} ${REPO_NAME}"

  # Create the trigger
  CREATE_OUTPUT=$(gcloud builds triggers create github \
    --name="${SERVICE}" \
    --region="${REGION}" \
    --project="${PROJECT}" \
    --repository="projects/${PROJECT}/locations/${REGION}/connections/${CONNECTION}/repositories/${REPO_NAME}" \
    --tag-pattern=".*" \
    --build-config="cloudbuild.yaml" \
    --service-account="${SERVICE_ACCOUNT}" \
    --substitutions="_GIT_ORG_=${GIT_ORG},_GIT_USER_=${GIT_USER},_GIT_TOKEN_=${GIT_TOKEN},_SECRET_ID_=${SECRET_ID}" \
    --include-logs-with-status 2>&1)

  CREATE_EXIT_CODE=$?

  if [ $CREATE_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}   ✓ Trigger created successfully${NC}"
    echo -e "${GREEN}   ✓ Trigger Name: ${BOLD}${SERVICE}${NC}"
    SUCCESS_COUNT=$((SUCCESS_COUNT+1))
  else
    echo -e "${RED}   ❌ Failed to create trigger${NC}"
    if [[ "$CREATE_OUTPUT" == *"already exists"* ]]; then
      echo -e "${YELLOW}   ⚠️  Trigger already exists${NC}"
    else
      echo -e "${RED}   Error details:${NC}"
      echo "$CREATE_OUTPUT" | while IFS= read -r line; do
        echo -e "${RED}   $line${NC}"
      done
    fi
    FAILED_COUNT=$((FAILED_COUNT+1))
    FAILED_TRIGGERS+=("$SERVICE")
  fi

  echo ""
done

# Final summary
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}📊 FINAL SUMMARY${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Successfully created: ${BOLD}${SUCCESS_COUNT}${NC} triggers"
echo -e "${RED}❌ Failed: ${BOLD}${FAILED_COUNT}${NC} triggers"
echo -e "${CYAN}🔨 Total processed: ${BOLD}${TOTAL}${NC} triggers"
echo ""

if [ $SUCCESS_COUNT -gt 0 ]; then
  echo -e "${GREEN}${BOLD}✓ Successfully created triggers:${NC}"
  for SERVICE in "${SERVICES[@]}"; do
    # Check if trigger is in failed list
    TRIGGER_FAILED=0
    for FAILED_TRIGGER in "${FAILED_TRIGGERS[@]}"; do
      if [[ "$FAILED_TRIGGER" == "$SERVICE" ]]; then
        TRIGGER_FAILED=1
        break
      fi
    done

    if [ $TRIGGER_FAILED -eq 0 ]; then
      REPO_NAME="${GIT_ORG}-${SERVICE}"
      echo -e "   ${GREEN}•${NC} ${SERVICE}"
      echo -e "     ${CYAN}Repository:${NC} ${REPO_NAME}"
      echo -e "     ${CYAN}Trigger:${NC}    Tag push (.*)"
    fi
  done
  echo ""
fi

if [ $FAILED_COUNT -gt 0 ]; then
  echo -e "${RED}${BOLD}✗ Failed triggers:${NC}"
  for FAILED_TRIGGER in "${FAILED_TRIGGERS[@]}"; do
    echo -e "   ${RED}•${NC} ${FAILED_TRIGGER}"
  done
  echo ""
fi

echo -e "${BLUE}📝 Next steps:${NC}"
echo -e "   ${CYAN}1.${NC} View triggers:"
echo -e "      ${BOLD}gcloud builds triggers list --region=${REGION} --project=${PROJECT}${NC}"
echo -e "   ${CYAN}2.${NC} View trigger details:"
echo -e "      ${BOLD}gcloud builds triggers describe TRIGGER_NAME --region=${REGION}${NC}"
echo -e "   ${CYAN}3.${NC} Test a trigger manually:"
echo -e "      ${BOLD}gcloud builds triggers run TRIGGER_NAME --region=${REGION} --tag=v1.0.0${NC}"
echo -e "   ${CYAN}4.${NC} View build history:"
echo -e "      ${BOLD}gcloud builds list --region=${REGION} --limit=10${NC}"
echo ""

if [ $SUCCESS_COUNT -eq $TOTAL ]; then
  echo -e "${GREEN}${BOLD}🎉 All triggers created successfully!${NC}"
  exit 0
else
  echo -e "${YELLOW}${BOLD}⚠️  Some triggers failed. Please check errors above.${NC}"
  exit 1
fi
