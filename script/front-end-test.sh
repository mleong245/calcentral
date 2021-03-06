#!/bin/bash

# Install the correct node version (specified in package.json) on Travis
if [ -d "${HOME}/.nvm" ] && [ "${TRAVIS}" = "true" ]; then
  source ${HOME}/.nvm/nvm.sh
  nvm install $(node -e 'console.log(require("./package.json").engines.node.replace(/[^\d\.]+/g, ""))')
fi

echo "Node version: $(node --version)"
npm config set strict-ssl false
npm install
npm run build-production

echo "Verify clean and consistent SCSS with scss_lint"
gem cleanup scss_lint
gem install scss_lint --version 0.49.0

scss-lint src/assets/stylesheets

lint_exit_status=$?
[[ ${lint_exit_status} -ne 0 ]] && echo "[ERROR] scss-lint returned non-zero status: ${lint_exit_status}" && exit 1 || echo '[INFO] scss-lint reported no problems'

exit 0
