/**
 * Chat state management with Zustand
 * Persists messages and sessionId to localStorage
 */

import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import { STORAGE_KEYS, VALIDATION } from '@/shared/lib/constants'
import type { ChatState, Message } from '../types'

/**
 * Generate a unique session ID
 */
function generateSessionId(): string {
  return crypto.randomUUID()
}

/**
 * Chat store with persistence
 */
export const useChatStore = create<ChatState>()(
  persist(
    (set) => ({
      // State
      messages: [],
      sessionId: generateSessionId(),

      // Actions
      addMessage: (message: Message) => {
        set((state) => {
          const newMessages = [...state.messages, message]

          // Limit stored messages to prevent localStorage overflow
          const limitedMessages = newMessages.slice(-VALIDATION.MAX_STORED_MESSAGES)

          return { messages: limitedMessages }
        })
      },

      clearChat: () => {
        set({
          messages: [],
          sessionId: generateSessionId(), // New session for fresh start
        })
      },
    }),
    {
      name: STORAGE_KEYS.MESSAGES, // localStorage key
      storage: createJSONStorage(() => localStorage),

      // Only persist messages and sessionId (not isInitialized)
      partialize: (state) => ({
        messages: state.messages,
        sessionId: state.sessionId,
      }),

      // Sync across tabs
      onRehydrateStorage: () => {
        return (_state, error) => {
          if (error) {
            console.error('Failed to rehydrate chat store:', error)
          }
        }
      },
    }
  )
)

/**
 * Sync store across browser tabs
 */
if (typeof window !== 'undefined') {
  window.addEventListener('storage', (e) => {
    if (e.key === STORAGE_KEYS.MESSAGES && e.newValue) {
      try {
        const data = JSON.parse(e.newValue)
        const state = data.state

        if (state) {
          useChatStore.setState({
            messages: state.messages || [],
            sessionId: state.sessionId || generateSessionId(),
          })
        }
      } catch (error) {
        console.error('Failed to sync chat store across tabs:', error)
      }
    }
  })
}
