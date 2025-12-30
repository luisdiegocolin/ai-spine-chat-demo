import { MarkdownRenderer } from './MarkdownRenderer'
import type { Message } from '../types'

interface ChatMessageProps {
  message: Message
}

export function ChatMessage({ message }: ChatMessageProps) {
  // User message: bubble on the right
  if (message.role === 'user') {
    return (
      <div className="flex justify-end">
        <div className="max-w-[70%] bg-white/90 text-slate-900 rounded-xl px-4 py-2.5">
          <p className="text-lg leading-relaxed wrap-break-words">{message.content}</p>
        </div>
      </div>
    )
  }

  // Error message: red accent
  if (message.role === 'error' || message.isError) {
    return (
      <div className="py-4 border-l-4 border-red-500/50 pl-4 bg-red-500/5 rounded-r-lg">
        <p className="text-sm text-red-400 leading-relaxed">{message.content}</p>
      </div>
    )
  }

  // Assistant message: markdown rendering
  return (
    <div className="py-4">
      <MarkdownRenderer content={message.content} />
    </div>
  )
}
