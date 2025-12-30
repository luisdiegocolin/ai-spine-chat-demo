import { Bot } from 'lucide-react'
import { useChat } from '../hooks'
import { useChatStore } from '../store'
import { ChatHeader } from './ChatHeader'
import { ChatMessages } from './ChatMessages'
import { ChatInput } from './ChatInput'
import { env } from '@/config/env'

const glassShellClass =
  'rounded-[26px] border border-white/10 bg-white/[0.02] p-0 shadow-[0_24px_72px_rgba(0,0,0,0.55)] overflow-hidden'

export function ChatContainer() {
  const { sendMessage, isLoading } = useChat()
  const { messages, clearChat } = useChatStore()

  const handleSendMessage = (message: string) => {
    sendMessage(message)
  }

  const handleClearChat = () => {
    if (confirm('Are you sure you want to clear the chat and start a new session?')) {
      clearChat()
    }
  }

  const hasMessages = messages.length > 0 || isLoading

  // Empty state: centered layout
  if (!hasMessages) {
    return (
      <div className={`${glassShellClass} h-screen flex flex-col`}>
        <ChatHeader onClearChat={handleClearChat} />
        <div className="flex-1 flex flex-col items-center justify-center p-5">
          <div className="w-full max-w-2xl space-y-6">
            {/* Placeholder content */}
            <div className="flex flex-col items-center text-center space-y-4">
              <div className="h-16 w-16 rounded-full flex items-center justify-center border border-white/15 bg-white/5">
                <Bot className="h-8 w-8 text-white/60" />
              </div>
              <div>
                <h3 className="text-lg font-semibold mb-2 text-white">Start a conversation</h3>
                <p className="text-white/70">
                  Send a message to start chatting with {env.agentName}.
                </p>
              </div>
            </div>

            {/* Input centered */}
            <div className="w-full">
              <ChatInput onSendMessage={handleSendMessage} isLoading={isLoading} />
            </div>
          </div>
        </div>
      </div>
    )
  }

  // With messages: normal layout
  return (
    <div className={`${glassShellClass} h-screen flex flex-col items-center`}>
      <div className="w-3/5">
        <ChatHeader onClearChat={handleClearChat} />
      </div>
      <div className="flex-1 w-3/5 flex flex-col min-h-0">
        <ChatMessages isLoading={isLoading} />
        <ChatInput onSendMessage={handleSendMessage} isLoading={isLoading} />
      </div>
    </div>
  )
}
