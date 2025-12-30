/**
 * Chat API endpoints
 */

import { apiClient } from './client'
import type { ChatRequest, ChatResponse } from '../types'

/**
 * Chat API
 */
export const chatAPI = {
  /**
   * Send a message to the agent via embed token
   *
   * @param request - Chat request with message and optional session_id
   * @returns Chat response with agent's reply
   *
   * @example
   * const response = await chatAPI.sendMessage({
   *   message: "Hello!",
   *   session_id: "uuid-123"
   * })
   */
  sendMessage: async (request: ChatRequest): Promise<ChatResponse> => {
    return apiClient.post<ChatResponse>('/agents/embed/chat', request)
  },

  // Future: streaming support
  // streamMessage: async (request: ChatRequest) => { ... }
}
