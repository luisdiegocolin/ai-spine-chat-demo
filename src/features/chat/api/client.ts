/**
 * API Client with retry logic and error handling
 */

import axios from 'axios'
import type { AxiosError, AxiosInstance, AxiosRequestConfig } from 'axios'
import { env } from '@/config/env'
import { API_ERRORS, ERROR_MESSAGES, RETRY_CONFIG } from '@/shared/lib/constants'
import type { APIError } from '../types'

/**
 * Custom error class for API errors
 */
export class APIClientError extends Error {
  statusCode: number
  errorCode?: string

  constructor(statusCode: number, errorCode?: string, message?: string) {
    super(message || ERROR_MESSAGES.DEFAULT)
    this.statusCode = statusCode
    this.errorCode = errorCode
    this.name = 'APIClientError'
  }

  static fromAxiosError(error: AxiosError): APIClientError {
    const status = error.response?.status || 500
    const data = error.response?.data as APIError | undefined

    return new APIClientError(
      status,
      data?.error_code,
      data?.detail || ERROR_MESSAGES[status as keyof typeof ERROR_MESSAGES] || ERROR_MESSAGES.DEFAULT
    )
  }
}

/**
 * Sleep utility for retry delays
 */
const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))

/**
 * Calculate exponential backoff delay
 */
function getRetryDelay(attempt: number): number {
  const delay = RETRY_CONFIG.INITIAL_DELAY * Math.pow(RETRY_CONFIG.BACKOFF_MULTIPLIER, attempt)
  return Math.min(delay, RETRY_CONFIG.MAX_DELAY)
}

/**
 * AI Spine API Client
 */
class AISpineClient {
  private client: AxiosInstance

  constructor() {
    this.client = axios.create({
      baseURL: env.apiBaseUrl,
      timeout: 30000, // 30 seconds
      headers: {
        'Content-Type': 'application/json',
      },
    })

    this.setupInterceptors()
  }

  /**
   * Setup request/response interceptors
   */
  private setupInterceptors() {
    // Request interceptor: Add Authorization header
    this.client.interceptors.request.use(
      (config) => {
        config.headers.Authorization = `Bearer ${env.embedToken}`
        return config
      },
      (error) => Promise.reject(error)
    )

    // Response interceptor: Handle errors
    this.client.interceptors.response.use(
      (response) => response,
      (error: AxiosError) => {
        if (error.response) {
          // Server responded with error
          throw APIClientError.fromAxiosError(error)
        } else if (error.request) {
          // Request was made but no response
          throw new APIClientError(
            API_ERRORS.TIMEOUT,
            'NETWORK_ERROR',
            'Network error. Please check your connection.'
          )
        } else {
          // Something else happened
          throw new APIClientError(500, 'UNKNOWN_ERROR', error.message)
        }
      }
    )
  }

  /**
   * POST request with retry logic
   */
  async post<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> {
    let lastError: APIClientError | null = null

    for (let attempt = 0; attempt <= env.maxRetries; attempt++) {
      try {
        const response = await this.client.post<T>(url, data, config)
        return response.data
      } catch (error) {
        lastError = error as APIClientError

        // Don't retry on certain errors
        if (
          lastError.statusCode === API_ERRORS.FORBIDDEN ||
          lastError.statusCode === API_ERRORS.UNAUTHORIZED
        ) {
          throw lastError
        }

        // Don't retry on last attempt
        if (attempt === env.maxRetries) {
          throw lastError
        }

        // Wait before retrying
        const delay = getRetryDelay(attempt)
        console.warn(
          `Request failed (attempt ${attempt + 1}/${env.maxRetries + 1}). Retrying in ${delay}ms...`,
          lastError.message
        )
        await sleep(delay)
      }
    }

    // Should never reach here, but TypeScript needs it
    throw lastError || new APIClientError(500, 'UNKNOWN_ERROR', 'Request failed')
  }

  /**
   * GET request (for future use)
   */
  async get<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.get<T>(url, config)
    return response.data
  }
}

// Export singleton instance
export const apiClient = new AISpineClient()
