import { useChat } from '../hooks'
import { useChatStore } from '../store'
import { ChatHeader } from './ChatHeader'
import { ChatMessages } from './ChatMessages'
import { ChatInput } from './ChatInput'

const glassShellClass =
  'rounded-[26px] border border-white/10 bg-white/[0.02] p-0 shadow-[0_24px_72px_rgba(0,0,0,0.55)] overflow-hidden flex flex-col'

export function ChatContainer() {
  const { sendMessage, isLoading } = useChat()
  const { clearChat } = useChatStore()

  const handleSendMessage = (message: string) => {
    sendMessage(message)
  }

  const handleClearChat = () => {
    if (confirm('Are you sure you want to clear the chat and start a new session?')) {
      clearChat()
    }
  }

  return (
    <div className={`${glassShellClass} h-screen`}>
      <ChatHeader onClearChat={handleClearChat} />
      <ChatMessages isLoading={isLoading} />
      <ChatInput onSendMessage={handleSendMessage} isLoading={isLoading} />
    </div>
  )
}
