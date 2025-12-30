import { useEffect, useRef } from 'react'
import { Bot } from 'lucide-react'
import { ChatMessage } from './ChatMessage'
import { TypingIndicator } from './TypingIndicator'
import { useChatStore } from '../store'
import { env } from '@/config/env'

interface ChatMessagesProps {
  isLoading: boolean
}

export function ChatMessages({ isLoading }: ChatMessagesProps) {
  const { messages } = useChatStore()
  const messagesEndRef = useRef<HTMLDivElement>(null)

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, isLoading])

  // Empty state
  if (messages.length === 0 && !isLoading) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center p-5 text-center space-y-4">
        <div className="h-16 w-16 rounded-full flex items-center justify-center border border-white/15 bg-white/5">
          <Bot className="h-8 w-8 text-white/60" />
        </div>
        <div>
          <h3 className="text-lg font-semibold mb-2 text-white">Start a conversation</h3>
          <p className="text-white/70 max-w-md">
            Send a message to start chatting with {env.agentName}.
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="flex-1 overflow-y-auto p-4 md:p-5 space-y-3 min-h-0">
        {messages.map((message, index) => (
          <ChatMessage key={index} message={message} />
        ))}

        {/* Typing indicator */}
        {isLoading && <TypingIndicator />}

      {/* Scroll anchor */}
      <div ref={messagesEndRef} />
    </div>
  )
}
