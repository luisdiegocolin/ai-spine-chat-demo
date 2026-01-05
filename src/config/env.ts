/**
 * Environment configuration
 * Validates and exports all environment variables
 */

function getEnvVar(key: string, required = true): string {
  const value = import.meta.env[key]

  if (required && !value) {
    throw new Error(`Missing required environment variable: ${key}`)
  }

  return value || ''
}

export const env = {
  // API Configuration
  apiBaseUrl: getEnvVar('VITE_API_BASE_URL'),
  embedToken: getEnvVar('VITE_EMBED_TOKEN'),

  // App Configuration
  appTitle: getEnvVar('VITE_APP_TITLE', false) || 'AI Spine Chat Demo',
  agentName: getEnvVar('VITE_AGENT_NAME', false) || 'AI Assistant',

  // Storage
  sessionStorageKey: getEnvVar('VITE_SESSION_STORAGE_KEY', false) || 'ai-spine-session',
  messagesStorageKey: getEnvVar('VITE_MESSAGES_STORAGE_KEY', false) || 'ai-spine-messages',

  // Limits
  maxMessageLength: parseInt(getEnvVar('VITE_MAX_MESSAGE_LENGTH', false) || '2000'),
  maxStoredMessages: parseInt(getEnvVar('VITE_MAX_STORED_MESSAGES', false) || '100'),

  // Retry Configuration
  maxRetries: parseInt(getEnvVar('VITE_MAX_RETRIES', false) || '3'),
  retryDelay: parseInt(getEnvVar('VITE_RETRY_DELAY', false) || '1000'),
} as const

// Validation warnings (dev only)
if (import.meta.env.DEV) {
  if (env.embedToken === 'aet_PLACEHOLDER' || !env.embedToken.startsWith('aet_')) {
    console.warn('⚠️  VITE_EMBED_TOKEN not configured or using placeholder')
  }

  if (env.apiBaseUrl.includes('localhost')) {
    console.info('🔧 Using local API:', env.apiBaseUrl)
  }
}
