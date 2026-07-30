<?php
declare(strict_types=1);
require '/app/cli/_cli.php';
cliInitUser("admin");

$controller = new FreshRSS_update_Controller();
$controller->checkInstallAction();
$view = $controller->view();
$ok = true;

// output based on `app/views/update/checkInstall.phtml`
echo '# ' . _t('gen.menu.check_install') . " (web version: https://localhost:8443/i/?c=update&a=checkInstall)\n\n";

echo '## ' . _t('install.check.php') . "\n";
foreach ($view->status_php as $key => $status) {
  if ($key === 'php') {
    echo _t("install.check.{$key}." . ($status === 'ok' ? 'ok' : 'nok'), PHP_VERSION, FRESHRSS_MIN_PHP_VERSION) . "\n";
  } else {
    echo _t("install.check.{$key}." . ($status === 'ok' ? 'ok' : 'nok')) . "\n";
  }
  if ($status !== 'ok') {
    $ok = false;
  }
}
echo "\n";

echo '## ' . _t('install.check.files') . "\n";
foreach ($view->status_files as $key => $status) {
  echo _t("install.check.{$key}." . ($status === 'ok' ? 'ok' : 'nok')) . "\n";
  if ($status !== 'ok') {
    $ok = false;
  }
}
echo "\n";

echo '## ' . _t('install.check.database-title') . "\n";
foreach ($view->status_database as $key => $status) {
  if ($key === 'table') {
    continue;
  }
  echo _t("install.check.database-{$key}." . ($status === true ? 'ok' : 'nok')) . "\n";
  if ($status !== true) {
    $ok = false;
  }
}
foreach ((array) $view->status_database['table'] as $key => $status) {
  echo _t('install.check.database-table.' . ($status === true ? 'ok' : 'nok'), $key) . "\n";
  if ($status !== true) {
    $ok = false;
  }
}

done($ok);
