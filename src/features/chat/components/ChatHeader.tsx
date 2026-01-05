import { Plus } from 'lucide-react'
import { env } from '@/config/env'

interface ChatHeaderProps {
  onClearChat: () => void
}

export function ChatHeader({ onClearChat }: ChatHeaderProps) {
  return (
    <div className="border-b border-white/10 px-6 md:px-8 py-5 md:py-6 shrink-0">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-[10px] font-semibold uppercase tracking-[0.3em] text-white/50">
            Agent Chat
          </p>
          <h1 className="text-xl md:text-2xl font-bold tracking-tight text-white">
            {env.agentName}
          </h1>
        </div>

        <button
          onClick={onClearChat}
          className="inline-flex items-center rounded-full border border-white/20 bg-white/10 text-sm font-semibold text-white transition-all duration-300 hover:border-white/40 hover:bg-white/20"
          style={{ gap: '0.75rem', paddingLeft: '0.875rem', paddingRight: '0.875rem', paddingTop: '0.375rem', paddingBottom: '0.375rem' }}
          title="Clear chat and start new session"
        >
          <Plus className="h-5 w-5" />
          New
        </button>
      </div>
    </div>
  )
}
