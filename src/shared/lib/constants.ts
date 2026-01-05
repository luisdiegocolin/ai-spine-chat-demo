/**
 * Application constants
 */

export const STORAGE_KEYS = {
  SESSION_ID: 'ai-spine-session-id',
  MESSAGES: 'ai-spine-messages',
} as const

export const API_ERRORS = {
  RATE_LIMIT: 429,
  FORBIDDEN: 403,
  UNAUTHORIZED: 401,
  SERVER_ERROR: 500,
  TIMEOUT: 408,
} as const

export const ERROR_MESSAGES = {
  [API_ERRORS.RATE_LIMIT]: 'Too many requests. Please wait a moment and try again.',
  [API_ERRORS.FORBIDDEN]: 'Access denied. Please check your configuration.',
  [API_ERRORS.UNAUTHORIZED]: 'Invalid or expired token.',
  [API_ERRORS.SERVER_ERROR]: 'Server error. Please try again later.',
  [API_ERRORS.TIMEOUT]: 'Request timeout. Please check your connection.',
  DEFAULT: 'An unexpected error occurred. Please try again.',
} as const

export const VALIDATION = {
  MIN_MESSAGE_LENGTH: 1,
  MAX_MESSAGE_LENGTH: 2000,
  MAX_STORED_MESSAGES: 100,
} as const

export const RETRY_CONFIG = {
  MAX_RETRIES: 3,
  INITIAL_DELAY: 1000, // 1 second
  MAX_DELAY: 10000, // 10 seconds
  BACKOFF_MULTIPLIER: 2, // Exponential backoff
} as const
