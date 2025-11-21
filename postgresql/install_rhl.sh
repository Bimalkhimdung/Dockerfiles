#!/bin/bash
# =============================================================================
# One-command PostgreSQL 17 installer for RHEL 9 & RHEL 8
# Run with: sudo bash this-script.sh
# sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Bimalkhimdung/devops-files/blob/main/postgresql/install_rhl.sh)"
# =============================================================================

set -euo pipefail

# -------------------------- CONFIG (change if you want) ----------------------
POSTGRES_VERSION=17                  # 17 is latest stable Nov 2025
POSTGRES_PASSWORD="postgres"  # ← CHANGE THIS IN PRODUCTION!
ALLOW_REMOTE=true                  # Set true if you want connections from other machines
# -----------------------------------------------------------------------------

echo "Installing PostgreSQL $POSTGRES_VERSION on RHEL..."

# 1. Install the official PostgreSQL YUM repository
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-$(rpm -E %rhel)-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# 2. Install PostgreSQL server + client
dnf install -y postgresql${POSTGRES_VERSION}-server postgresql${POSTGRES_VERSION}

# 3. Initialize the database (only needed first time)
if [[ ! -d /var/lib/pgsql/${POSTGRES_VERSION}/data/base ]]; then
    echo "Initializing PostgreSQL database..."
    /usr/pgsql-${POSTGRES_VERSION}/bin/postgresql-${POSTGRES_VERSION}-setup initdb
fi

# 4. Enable and start PostgreSQL
systemctl enable postgresql-${POSTGRES_VERSION}
systemctl start postgresql-${POSTGRES_VERSION}

# 5. Set password for the 'postgres' OS user (so you can sudo -u postgres easily)
echo "Setting password for OS user 'postgres'..."
echo "$POSTGRES_PASSWORD" | passwd --stdin postgres

# 6. Switch to postgres user and configure database superuser password
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$POSTGRES_PASSWORD';"

# 7. (Optional) Allow remote connections
if [[ "$ALLOW_REMOTE" == true ]]; then
    echo "Enabling remote connections..."
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/${POSTGRES_VERSION}/data/postgresql.conf
    echo "host    all             all             0.0.0.0/0            md5" >> /var/lib/pgsql/${POSTGRES_VERSION}/data/pg_hba.conf
    systemctl restart postgresql-${POSTGRES_VERSION}
fi

# 9. Final message
clear
echo "============================================================"
echo " PostgreSQL $POSTGRES_VERSION is successfully installed!"
echo "============================================================"
echo ""
echo "Connection info:"
echo "   Local:   psql -U postgres -h localhost"
echo "   Remote:  psql -U postgres -h $(hostname -I | awk '{print $1}')"
echo ""
echo "Login credentials:"
echo "   Username: postgres"
echo "   Password: $POSTGRES_PASSWORD"
echo ""
echo "Quick test:"
echo "   sudo -u postgres psql -c \"SELECT version();\""
echo ""
echo "Useful commands:"
echo "   systemctl status postgresql-$POSTGRES_VERSION"
echo "   sudo -u postgres psql"
echo "   pg_isready"
echo "============================================================"

echo "Done! Your PostgreSQL server is ready."

exit 0
