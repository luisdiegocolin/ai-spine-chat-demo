/**
 * Chat hook with React Query integration
 * Handles sending messages and updating state
 */

import { useMutation } from '@tanstack/react-query'
import { useChatStore } from '../store'
import { chatAPI, APIClientError } from '../api'
import type { Message } from '../types'

/**
 * Hook for chat functionality
 *
 * @returns {object} Chat methods and state
 *
 * @example
 * const { sendMessage, isLoading, error } = useChat()
 *
 * const handleSend = async () => {
 *   await sendMessage("Hello!")
 * }
 */
export function useChat() {
  const { sessionId, addMessage } = useChatStore()

  const mutation = useMutation({
    mutationFn: async (message: string) => {
      // Call API
      const response = await chatAPI.sendMessage({
        message,
        session_id: sessionId,
      })

      return response
    },

    onMutate: async (message: string) => {
      // Optimistic update: Add user message immediately
      const userMessage: Message = {
        role: 'user',
        content: message,
        timestamp: new Date().toISOString(),
      }

      addMessage(userMessage)
    },

    onSuccess: (response) => {
      // Add assistant response to store
      const assistantMessage: Message = {
        role: 'assistant',
        content: response.response,
        timestamp: new Date().toISOString(),
      }

      addMessage(assistantMessage)
    },

    onError: (error) => {
      // Get user-friendly error message
      let errorText = 'Failed to send message. Please try again.'

      if (error instanceof APIClientError) {
        errorText = error.message
      } else if (error instanceof Error) {
        errorText = error.message
      }

      // Add error message to chat
      const errorMessage: Message = {
        role: 'error',
        content: errorText,
        timestamp: new Date().toISOString(),
        isError: true,
      }

      addMessage(errorMessage)

      // Also log for debugging
      console.error('Failed to send message:', error)
    },
  })

  return {
    /**
     * Send a message to the agent
     */
    sendMessage: mutation.mutate,

    /**
     * Send a message and wait for response (returns promise)
     */
    sendMessageAsync: mutation.mutateAsync,

    /**
     * Is the request currently loading?
     */
    isLoading: mutation.isPending,

    /**
     * Error from the last request (if any)
     */
    error: mutation.error,

    /**
     * Reset error state
     */
    reset: mutation.reset,
  }
}
