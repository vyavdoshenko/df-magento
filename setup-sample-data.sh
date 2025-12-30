#!/bin/bash
set -e

# Setup Sample Data for Magento Load Testing
# This script populates Magento with products, categories, and customers

MAGENTO_DIR="/var/www/html/magento"
cd ${MAGENTO_DIR}

echo "============================================"
echo "  Magento Sample Data Setup"
echo "============================================"

# Step 0: Ensure Composer auth is configured
echo ""
echo "Step 0: Configuring Composer authentication..."
mkdir -p ~/.composer
cat > ~/.composer/auth.json << EOF
{
    "http-basic": {
        "repo.magento.com": {
            "username": "${ADOBE_PUBLIC_KEY}",
            "password": "${ADOBE_PRIVATE_KEY}"
        }
    }
}
EOF

# Step 1: Deploy official Magento sample data
echo ""
echo "Step 1: Installing Magento Sample Data..."
echo "(This downloads ~300MB and takes several minutes)"
echo ""

php -d memory_limit=4G bin/magento sampledata:deploy

echo ""
echo "Step 2: Running setup:upgrade..."
php -d memory_limit=4G bin/magento setup:upgrade

echo ""
echo "Step 3: Compiling DI..."
php -d memory_limit=4G bin/magento setup:di:compile

echo ""
echo "Step 4: Deploying static content for all themes..."
php -d memory_limit=4G bin/magento setup:static-content:deploy -f --theme Magento/blank --theme Magento/luma
php -d memory_limit=4G bin/magento setup:static-content:deploy -f --area adminhtml

echo ""
echo "Step 5: Reindexing..."
php -d memory_limit=4G bin/magento indexer:reindex

echo ""
echo "Step 6: Setting permissions..."
chown -R www-data:www-data /var/www/html/magento
chmod -R 777 /var/www/html/magento/var /var/www/html/magento/pub/static /var/www/html/magento/pub/media /var/www/html/magento/generated

echo ""
echo "Step 7: Flushing cache..."
php -d memory_limit=4G bin/magento cache:flush

echo ""
echo "Step 8: Warming up Full Page Cache..."
URLS=(
    "/"
    "/women.html"
    "/men.html"
    "/gear.html"
    "/training.html"
    "/sale.html"
    "/women/tops-women.html"
    "/women/bottoms-women.html"
    "/men/tops-men.html"
    "/men/bottoms-men.html"
    "/gear/bags.html"
    "/gear/fitness-equipment.html"
)

BASE_URL="${MAGENTO_URL:-http://192.168.0.126}"
for url in "${URLS[@]}"; do
    echo "Warming: ${BASE_URL}${url}"
    curl -s -o /dev/null "${BASE_URL}${url}" || true
done

echo ""
echo "============================================"
echo "  Sample Data Setup Complete!"
echo "============================================"
echo ""
echo "Installed:"
echo "  - 6 categories"
echo "  - 46 configurable products"
echo "  - 2000+ simple products"
echo "  - Sample customers"
echo "  - Sample orders"
echo ""
echo "URLs for testing:"
echo "  - Homepage:  ${BASE_URL}/"
echo "  - Women:     ${BASE_URL}/women.html"
echo "  - Men:       ${BASE_URL}/men.html"
echo "  - Gear:      ${BASE_URL}/gear.html"
echo "  - Search:    ${BASE_URL}/catalogsearch/result/?q=jacket"
echo ""
