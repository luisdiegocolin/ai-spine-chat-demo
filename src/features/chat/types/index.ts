/**
 * Chat feature types
 * Maps to backend Pydantic models
 */

/**
 * Message role (user or assistant)
 */
export type MessageRole = 'user' | 'assistant'

/**
 * Single chat message
 */
export interface Message {
  role: MessageRole
  content: string
  timestamp: string
}

/**
 * Request to send a message to the agent
 * Maps to: EmbedChatRequest (backend)
 */
export interface ChatRequest {
  message: string
  session_id?: string
  metadata?: Record<string, any>
}

/**
 * Response from the agent
 * Maps to: ChatResponse (backend)
 */
export interface ChatResponse {
  agent_id: string
  response: string
  session_id: string
  usage?: {
    tokens: number
    model: string
  }
  execution_time_ms?: number
  pagination?: {
    total_pages: number
    page_index: number
    page_size: number
    continuation_id: string
  }
}

/**
 * Error response from API
 */
export interface APIError {
  detail: string
  error_code?: string
  status_code: number
}

/**
 * Chat state for Zustand store
 */
export interface ChatState {
  messages: Message[]
  sessionId: string
  isInitialized: boolean

  // Actions
  addMessage: (message: Message) => void
  clearChat: () => void
  initializeSession: () => void
}
