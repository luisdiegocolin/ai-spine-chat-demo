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
        <div className="max-w-[70%] bg-white/90 text-slate-900 rounded-xl" style={{ paddingLeft: '1.25rem', paddingRight: '1.25rem', paddingTop: '0.75rem', paddingBottom: '0.75rem' }}>
          <p className="text-sm leading-relaxed wrap-break-words">{message.content}</p>
        </div>
      </div>
    )
  }

  // Error message: red accent
  if (message.role === 'error' || message.isError) {
    return (
      <div className="border-l-4 border-red-500/50 bg-red-500/5 rounded-r-lg" style={{ paddingTop: '1rem', paddingBottom: '1rem', paddingLeft: '1rem' }}>
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
