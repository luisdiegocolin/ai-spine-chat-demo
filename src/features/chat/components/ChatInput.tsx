import { useState, useRef, useEffect } from 'react'
import { Send, Loader2 } from 'lucide-react'
import { VALIDATION } from '@/shared/lib/constants'

interface ChatInputProps {
  onSendMessage: (message: string) => void
  isLoading: boolean
}

export function ChatInput({ onSendMessage, isLoading }: ChatInputProps) {
  const [message, setMessage] = useState('')
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  const handleSend = () => {
    const trimmed = message.trim()
    if (!trimmed || isLoading) return

    onSendMessage(trimmed)
    setMessage('')
  }

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  // Auto-resize textarea
  const handleInput = (e: React.FormEvent<HTMLTextAreaElement>) => {
    const target = e.target as HTMLTextAreaElement
    target.style.height = 'auto'
    target.style.height = `${Math.min(Math.max(target.scrollHeight, 56), 200)}px`
  }

  // Reset textarea height when message is cleared
  useEffect(() => {
    if (!message && textareaRef.current) {
      textareaRef.current.style.height = '56px'
    }
  }, [message])

  const isDisabled = !message.trim() || isLoading
  const isOverLimit = message.length > VALIDATION.MAX_MESSAGE_LENGTH

  return (
    <div className="border-t border-white/10 bg-white/5 rounded-b-[26px]">
      <div className="relative px-2 pb-2 pt-4 sm:px-4 sm:pb-4">
        <textarea
          ref={textareaRef}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          onKeyDown={handleKeyPress}
          onInput={handleInput}
          placeholder="Type your message..."
          className="w-full rounded-[24px] border border-white/10 bg-white/5 px-6 py-4 pr-24 text-sm text-white placeholder:text-white/60 focus:outline-none focus:ring-2 focus:ring-white/40 min-h-[56px] max-h-[200px] resize-none overflow-y-auto [&::-webkit-scrollbar]:hidden [-ms-overflow-style:none] [scrollbar-width:none]"
          rows={1}
        />

        {/* Character count (show when close to limit) */}
        {message.length > VALIDATION.MAX_MESSAGE_LENGTH * 0.8 && (
          <div className={`absolute left-6 bottom-6 text-xs ${isOverLimit ? 'text-red-400' : 'text-white/60'}`}>
            {message.length} / {VALIDATION.MAX_MESSAGE_LENGTH}
          </div>
        )}

        {/* Send button */}
        <div className="absolute right-6 top-4 bottom-4 flex items-center">
          <button
            onClick={handleSend}
            disabled={isDisabled || isOverLimit}
            className={`flex items-center justify-center w-9 h-9 rounded-full transition-all duration-200 ${
              !isDisabled && !isOverLimit
                ? 'bg-[#d8ffb3] text-slate-900 shadow-[0_10px_30px_rgba(0,0,0,0.45)] hover:shadow-[0_15px_40px_rgba(0,0,0,0.5)] hover:scale-105'
                : 'bg-white/5 text-white/40 cursor-not-allowed'
            }`}
          >
            {isLoading ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Send className="h-4 w-4" />
            )}
          </button>
        </div>
      </div>
    </div>
  )
}
