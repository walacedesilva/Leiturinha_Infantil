const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, '..');

const config = getDefaultConfig(projectRoot);

// Permite que o Metro resolva arquivos fora da pasta react-native/,
// como ../assets/audio/, ../assets/fonts/, etc.
config.watchFolders = [workspaceRoot];

// Garante que node_modules seja resolvido a partir do projectRoot
// mesmo quando o arquivo importador está fora (e.g. ../assets/).
config.resolver.nodeModulesPaths = [path.resolve(projectRoot, 'node_modules')];

module.exports = config;
